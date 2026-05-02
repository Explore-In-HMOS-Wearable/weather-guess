import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import Logger from '../utils/Logger';
import { Constants } from '../constants/Constants';
import { NavigationService } from '../services/NavigationService';

@Component
export struct StatsScreen {
  @State gamesPlayed: number = 0;
  @State bestScore: number = 0;
  @State avgScore: string = '0.0';
  @State accuracy: string = '0%';

  private readonly PREFS_NAME: string = 'weather_guess_prefs';
  private readonly KEY_BEST_SCORE: string = 'best_score';
  private readonly KEY_GAMES_PLAYED: string = 'games_played';
  private readonly KEY_TOTAL_SCORE: string = 'total_score';
  private readonly KEY_TOTAL_CORRECT: string = 'total_correct';
  private readonly KEY_TOTAL_GUESSES: string = 'total_guesses';

  navigationService: NavigationService = NavigationService.getInstance();

  aboutToAppear(): void {
    this.loadStats();
  }

  private loadStats(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const prefs = preferences.getPreferencesSync(ctx, { name: this.PREFS_NAME });
      this.gamesPlayed = prefs.getSync(this.KEY_GAMES_PLAYED, 0) as number;
      this.bestScore = prefs.getSync(this.KEY_BEST_SCORE, 0) as number;
      const totalScore = prefs.getSync(this.KEY_TOTAL_SCORE, 0) as number;
      const totalCorrect = prefs.getSync(this.KEY_TOTAL_CORRECT, 0) as number;
      const totalGuesses = prefs.getSync(this.KEY_TOTAL_GUESSES, 0) as number;

      if (this.gamesPlayed > 0) {
        this.avgScore = (totalScore / this.gamesPlayed).toFixed(1);
      } else {
        this.avgScore = '—';
      }

      if (totalGuesses > 0) {
        const pct = Math.round((totalCorrect / totalGuesses) * 100);
        this.accuracy = `${pct}%`;
      } else {
        this.accuracy = '—';
      }
    } catch (e) {
      Logger.warn('Could not load stats:', String(e));
    }
  }

  build() {
    Column({ space: 8 }) {
      Text($r('app.string.stats_title'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(0x333333)
        .margin({ top: 16 })

      Column({ space: 6 }) {
        this.StatRow($r('app.string.stats_games_played'), `${this.gamesPlayed}`)
        this.StatRow($r('app.string.stats_best_score'), `${this.bestScore}`)
        this.StatRow($r('app.string.stats_avg_score'), this.avgScore)
        this.StatRow($r('app.string.stats_accuracy'), this.accuracy)
      }
      .width('85%')
      .padding(12)
      .borderRadius(10)
      .backgroundColor(Color.White)

    }
    .width(Constants.FULL_PERCENT)
    .height(Constants.FULL_PERCENT)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
  }

  @Builder
  StatRow(label: ResourceStr, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(0x666666)
        .flexGrow(1)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(0x222222)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}
