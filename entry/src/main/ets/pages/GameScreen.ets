import { CityModel } from '../model/CityModel'
import Logger from '../utils/Logger'
import { Color } from '@kit.ArkGraphics3D';
import { Constants } from '../constants/Constants';
import { NavigationService } from '../services/NavigationService';
import { SceneController } from '../utils/SceneController';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { vibrator } from '@kit.SensorServiceKit';

@Component
export struct WeatherGuessGame {
  @State sceneOpt: SceneOptions | null = null;
  @State currentIndex: number = 0
  @State guessTemp: number = 20
  @State score: number = 0
  @State timeLeft: number = 10
  @State resultEmoji: string = ''
  @State showAnimation: boolean = false
  @State round: number = 1
  @State gameOver: boolean = false
  @State correctGuesses: number = 0
  @State resultLabel: string = ''
  @State resultColor: string = '#888888'
  @State resultActual: string = ''
  @State difficulty: number = 1
  @State isDailyMode: boolean = false
  @State isDailyBadgeVisible: boolean = false
  @State selectedCities: CityModel[] = [];
  @State currentSeasonIndex: number = 0;
  @State bestScore: number = 0;

  private maxRounds: number = 3
  private timer: number | null = null
  private readonly PREFS_NAME: string = 'weather_guess_prefs';
  private readonly KEY_BEST_SCORE: string = 'best_score';
  private readonly KEY_GAMES_PLAYED: string = 'games_played';
  private readonly KEY_TOTAL_SCORE: string = 'total_score';
  private readonly KEY_TOTAL_CORRECT: string = 'total_correct';
  private readonly KEY_TOTAL_GUESSES: string = 'total_guesses';

  private readonly allCities: CityModel[] = [
    new CityModel(1, 'Istanbul', [15, 28, 17, 6], 'Europe'),
    new CityModel(2, 'Paris', [12, 24, 14, 5], 'Europe'),
    new CityModel(3, 'Tokyo', [15, 29, 20, 6], 'Asia'),
    new CityModel(4, 'New York', [13, 28, 16, 2], 'Americas'),
    new CityModel(5, 'Berlin', [10, 24, 12, 1], 'Europe'),
    new CityModel(6, 'London', [11, 21, 13, 5], 'Europe'),
    new CityModel(7, 'Moscow', [8, 22, 9, -6], 'Europe'),
    new CityModel(8, 'Dubai', [28, 38, 33, 20], 'Asia'),
    new CityModel(9, 'Sydney', [19, 26, 20, 14], 'Oceania'),
    new CityModel(10, 'Cairo', [22, 34, 27, 14], 'Africa')
  ];

  private sceneCtrl: SceneController = new SceneController(
    $rawfile('gltf/flower/scene.gltf'),
    Constants.ANIMATION_OPTION
  );

  navigationService: NavigationService = NavigationService.getInstance();

  // ── Haptic feedback (P4-T2) ────────────────────────────────────────────────

  /**
   * Vibrate with a short double-tap pattern for correct guesses,
   * or a single long pulse for misses/timeouts.
   */
  private vibrate(isCorrect: boolean): void {
    try {
      if (isCorrect) {
        // Short double-tap: 40ms on, 60ms off, 40ms on
        vibrator.startVibration(
          { type: 'time', duration: 40 },
          { id: 0, usage: 'touch' }
        );
        setTimeout(() => {
          vibrator.startVibration(
            { type: 'time', duration: 40 },
            { id: 0, usage: 'touch' }
          );
        }, 100);
      } else {
        // Single long pulse: 120ms
        vibrator.startVibration(
          { type: 'time', duration: 120 },
          { id: 0, usage: 'touch' }
        );
      }
    } catch (e) {
      // Graceful degradation — vibrator may not be available on all devices
      Logger.warn('Vibration unavailable:', String(e));
    }
  }

  // ── Preferences helpers ────────────────────────────────────────────────────

  private loadBestScore(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const prefs = preferences.getPreferencesSync(ctx, { name: this.PREFS_NAME });
      const stored = prefs.getSync(this.KEY_BEST_SCORE, 0);
      this.bestScore = typeof stored === 'number' ? stored : 0;
    } catch (e) {
      Logger.warn('Could not load best score:', String(e));
    }
  }

  private saveBestScore(score: number): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const prefs = preferences.getPreferencesSync(ctx, { name: this.PREFS_NAME });
      if (score > this.bestScore) {
        this.bestScore = score;
        prefs.putSync(this.KEY_BEST_SCORE, score);
      }
      // Update cumulative stats
      const gamesPlayed = (prefs.getSync(this.KEY_GAMES_PLAYED, 0) as number) + 1;
      const totalScore = (prefs.getSync(this.KEY_TOTAL_SCORE, 0) as number) + score;
      const totalCorrect = (prefs.getSync(this.KEY_TOTAL_CORRECT, 0) as number) + this.correctGuesses;
      const totalGuesses = (prefs.getSync(this.KEY_TOTAL_GUESSES, 0) as number) + this.maxRounds;
      prefs.putSync(this.KEY_GAMES_PLAYED, gamesPlayed);
      prefs.putSync(this.KEY_TOTAL_SCORE, totalScore);
      prefs.putSync(this.KEY_TOTAL_CORRECT, totalCorrect);
      prefs.putSync(this.KEY_TOTAL_GUESSES, totalGuesses);
      prefs.flush();
    } catch (e) {
      Logger.warn('Could not save stats:', String(e));
    }
  }

  // ── City selection ─────────────────────────────────────────────────────────

  /**
   * Simple LCG pseudo-random generator seeded by a number.
   * Returns values in [0, 1).
   */
  private lcgRandom(seed: number): () => number {
    let state = seed >>> 0;
    return (): number => {
      // Park-Miller LCG constants
      state = Math.imul(1664525, state) + 1013904223 >>> 0;
      return state / 0x100000000;
    };
  }

  private pickRandomCities(): void {
    const pool: CityModel[] = [...this.allCities];

    let rand: () => number;
    if (this.isDailyMode) {
      // Seed from today's date: YYYYMMDD
      const now = new Date();
      const seed = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
      rand = this.lcgRandom(seed);
    } else {
      let seed = Date.now();
      rand = (): number => {
        seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
        return (seed >>> 0) / 0x100000000;
      };
    }

    // Fisher-Yates shuffle using chosen RNG
    for (let i = pool.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      const temp = pool[i];
      pool[i] = pool[j];
      pool[j] = temp;
    }
    this.selectedCities = pool.slice(0, this.maxRounds);
    // Season index from same RNG
    this.currentSeasonIndex = Math.floor(rand() * 4);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  aboutToAppear(): void {
    // Read settings set by HomeScreen via shared NavigationService
    this.difficulty = this.navigationService.difficulty;
    this.isDailyMode = this.navigationService.isDailyMode;
    this.isDailyBadgeVisible = this.isDailyMode;
    this.loadBestScore()
    this.pickRandomCities()
    this.startTimer()
    this.initScene()
  }

  onPageHide(): void {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.sceneCtrl.destroy();
    this.sceneOpt = null;
  }

  // ── 3D Scene ───────────────────────────────────────────────────────────────

  private initScene(): void {
    this.sceneCtrl.onReady((opt: SceneOptions) => {
      // Apply flower-specific node rotation after scene loads
      const scene = this.sceneCtrl.scene;
      if (scene && scene.root) {
        const node = scene.root.getNodeByPath('Sketchfab_Scene/Sketchfab_model/root/GLTF_SceneRootNode');
        if (node) {
          const angle = Math.PI / 6;
          node.rotation = {
            x: Math.sin(angle / 2),
            y: 0,
            z: 0,
            w: Math.cos(angle / 2)
          };
        } else {
          Logger.warn('GameScreen: flower root node not found');
        }
      }
      this.sceneOpt = opt;
    });
    this.sceneCtrl.init(this.getUIContext());
  }

  // ── Game logic ─────────────────────────────────────────────────────────────

  startTimer(): void {
    this.timeLeft = 10
    if (this.timer) {
      clearInterval(this.timer)
    }
    this.timer = setInterval(() => {
      if (this.timeLeft > 0) {
        this.timeLeft--
      } else {
        clearInterval(this.timer)
        this.showResult(false)
      }
    }, 1000)
  }

  showResult(isGuess: boolean): void {
    let actual = this.selectedCities[this.currentIndex].dailyTemperatures[this.currentSeasonIndex]
    let diff = Math.abs(actual - this.guessTemp)

    const closeWindow: number = this.difficulty === 0 ? 8 : (this.difficulty === 2 ? 4 : 6);

    this.resultActual = `Actual: ${actual}°C`

    if (!isGuess) {
      this.resultLabel = "Time's Up!"
      this.resultColor = '#CC3333'
      this.resultEmoji = `Time's Up! Actual: ${actual}°C`
      this.vibrate(false)
    } else if (diff === 0) {
      this.resultLabel = 'Perfect!'
      this.resultColor = '#22AA44'
      this.resultEmoji = `Perfect! Actual: ${actual}°C`
      this.score += 2;
      this.correctGuesses += 1;
      this.vibrate(true)
    } else if (diff <= 3) {
      this.resultLabel = 'So Close!'
      this.resultColor = '#22AA44'
      this.resultEmoji = `So Close! Actual: ${actual}°C`
      this.score += 1;
      this.correctGuesses += 1;
      this.vibrate(true)
    } else if (diff <= closeWindow) {
      this.resultLabel = 'Not Bad!'
      this.resultColor = '#E07000'
      this.resultEmoji = `Not Bad! Actual: ${actual}°C`
      this.vibrate(false)
    } else {
      this.resultLabel = 'Missed!'
      this.resultColor = '#CC3333'
      this.resultEmoji = `Missed! Actual: ${actual}°C`
      this.vibrate(false)
    }

    this.showAnimation = true
    clearInterval(this.timer)

    setTimeout(() => {
      if (this.round >= this.maxRounds) {
        this.saveBestScore(this.score)
        this.gameOver = true
      } else {
        this.nextRound()
      }
    }, 2000)
  }

  nextRound(): void {
    this.currentIndex = (this.currentIndex + 1) % this.selectedCities.length
    this.round += 1
    this.showAnimation = false
    this.resultEmoji = ''
    this.startTimer()
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  build() {
    if (this.gameOver) {
      Stack() {
        if (this.score >= 3) {
          Column() {
            if (this.sceneOpt) {
              Component3D(this.sceneOpt)
                .renderWidth($r('app.string.full_percent_str'))
                .renderHeight($r('app.string.full_percent_str'))
                .backgroundColor(Color.Transparent)
                .onAppear(() => {
                  this.sceneCtrl.backAnimator?.play();
                })
            } else {
              Text($r('app.string.loading')).fontColor(Color.Black)
            }
          }
          .width(Constants.FULL_PERCENT)
          .height(Constants.FULL_PERCENT)
          .borderRadius($r('app.float.board_radius_normal'))
          .justifyContent(FlexAlign.Center)
        }

        Column() {
          if (this.score >= 3) {
            Text($r('app.string.result_congratulations'))
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Green)
          } else {
            Text($r('app.string.result_game_over'))
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Red)
          }
          Text(`Correct: ${this.correctGuesses}/${this.maxRounds}`)
            .fontSize(16)
            .fontColor(Color.Gray)
          Text(`Score: ${this.score}`)
            .fontSize(16)
            .fontColor(Color.Gray)
          Text(`Best: ${this.bestScore}`)
            .fontSize(14)
            .fontColor('#888888')
          if (this.isDailyBadgeVisible) {
            Text($r('app.string.daily_badge'))
              .fontSize(11)
              .fontColor('#AA7700')
              .fontWeight(FontWeight.Bold)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(8)
              .backgroundColor('#FFF3CC')
              .margin({ top: 4 })
          }
          Button($r('app.string.btn_return_home'))
            .onClick(() => {
              this.navigationService.pageInfos.clear()
              this.currentIndex = 0
              this.guessTemp = 20
              this.score = 0
              this.timeLeft = 10
              this.resultEmoji = ''
              this.showAnimation = false
              this.round = 1
              this.gameOver = false
              this.correctGuesses = 0
              this.pickRandomCities()
            })
            .fontSize(12)
            .width('50%')
            .height(24)
            .borderRadius(14)
            .margin({ top: 10 })
            .backgroundColor(0x007AFF)
            .fontColor(Color.White)
          Button($r('app.string.btn_stats'))
            .onClick(() => {
              this.navigationService.pageInfos.pushPath({ name: 'Stats' })
            })
            .fontSize(12)
            .width('50%')
            .height(24)
            .borderRadius(14)
            .margin({ top: 4 })
            .backgroundColor(0x888888)
            .fontColor(Color.White)
        }.alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      }

    } else {
      Column({ space: 6 }) {
        // Round indicator + live score (P2-T1)
        Row() {
          Text(`Round ${this.round}/${this.maxRounds}`)
            .fontSize(13)
            .fontColor(Color.Gray)
          Text(`  Score: ${this.score}`)
            .fontSize(13)
            .fontColor(Color.Gray)
        }
        .margin({ top: 10 })

        Text(this.selectedCities.length > 0 ? this.selectedCities[this.currentIndex].name : '')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)

        if (!this.showAnimation) {
          // Circular countdown timer (P2-T4)
          Stack() {
            Progress({
              value: this.timeLeft,
              total: 10,
              type: ProgressType.Ring
            })
              .width(52)
              .height(52)
              .color(this.timeLeft > 6 ? '#22AA44' : this.timeLeft > 3 ? '#E07000' : '#CC3333')
              .backgroundColor('#E0E0E0')
              .style({ strokeWidth: 5 })
            Text(`${this.timeLeft}`)
              .fontSize(16)
              .fontColor(Color.Black)
              .fontWeight(FontWeight.Bold)
          }

          Text(`${this.guessTemp}°C`)
            .fontSize(22)
            .fontColor(Color.Blue)

          Slider({
            value: this.guessTemp,
            min: -10,
            max: 40,
            step: 1
          })
            .onChange((value) => {
              this.guessTemp = Math.round(value)
            })
            .margin({ left: 12, right: 12 })

          Button($r('app.string.btn_guess'))
            .onClick(() => this.showResult(true))
            .fontSize(13)
            .width('42%')
            .height(28)
            .borderRadius(14)
            .backgroundColor(0x007AFF)
            .fontColor(Color.White)
        } else {
          // Styled result feedback (P2-T2)
          Column({ space: 4 }) {
            Text(this.resultLabel)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.resultColor)
            Text(this.resultActual)
              .fontSize(16)
              .fontColor(Color.Gray)
          }
          .padding(12)
          .borderRadius(10)
          .backgroundColor(Color.White)
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
  }
}
