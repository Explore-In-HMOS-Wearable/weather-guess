import { CityModel } from '../model/CityModel'
import Logger from '../utils/Logger'
import { AnimatorResult, router } from '@kit.ArkUI'
import { Constants } from '../constants/Constants';
import { Animation, Camera, EnvironmentBackgroundType, Node, Scene, SceneResourceFactory, Color } from '@kit.ArkGraphics3D';

@Entry
@Component
struct WeatherGuessGame {
  @State sceneOpt: SceneOptions | null = null;
  @State progressValue: number = 0;
  @State animationEnabled: Boolean = false;
  @State animationDuration: number = 0;
  @State animationIsRunning: Boolean = false;
  @State animationCallbackInvoked: string = Constants.STRING_NO;
  @State enable: boolean = true;
  scene: Scene | null = null;
  cam: Camera | null = null;
  backAnimator: AnimatorResult | undefined = undefined;
  anim: Animation | null = null;
  private readonly SHAKE_THRESHOLD: number = 12;
  @State isNewGame: boolean = false;

  @State currentIndex: number = 0
  @State guessTemp: number = 20
  @State score: number = 0
  @State timeLeft: number = 10
  @State resultEmoji: string = ''
  @State showAnimation: boolean = false
  @State round: number = 1
  @State gameOver: boolean = false
  @State correctGuesses: number = 0
  private maxRounds: number = 3
  private timer: number | null = null
  private cities: CityModel[] = [
    new CityModel(1, 'Istanbul', [24]),
    new CityModel(2, 'Paris', [18]),
    new CityModel(3, 'Tokyo', [27]),
    new CityModel(4, 'New York', [22]),
    new CityModel(5, 'Berlin', [16]),
    new CityModel(6, 'London', [19]),
    new CityModel(7, 'Moscow', [10]),
    new CityModel(8, 'Dubai', [34]),
    new CityModel(9, 'Sydney', [26]),
    new CityModel(10, 'Cairo', [31]),
  ];

  onJumpClick(target_url: string): void {
    this.getUIContext().getRouter().pushUrl({ url: target_url }, router.RouterMode.Single, (err) => {
      if (err) {
        Logger.error('TAG', `Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
    });
  }

  aboutToAppear() {
    this.startTimer()
    this.init()
  }

  startTimer() {
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

  showResult(isGuess: boolean) {
    let actual = this.cities[this.currentIndex].dailyTemperatures[0]
    let diff = Math.abs(actual - this.guessTemp)

    if (!isGuess) {
      this.resultEmoji = `⏳ Your Time's Up! Actual: ${actual}°C`
    } else if (diff === 0) {
      this.resultEmoji = `🎯 Perfect! Actual: ${actual}°C`;
      this.score += 2;
      this.correctGuesses += 1;
    } else if (diff <= 3) {
      this.resultEmoji = `🔥 So Close! Actual: ${actual}°C`;
      this.score += 1;
      this.correctGuesses += 1;
    } else if (diff <= 6) {
      this.resultEmoji = `👍 Not Bad! Actual: ${actual}°C`;
    } else {
      this.resultEmoji = `❄️ You Stayed Away! Actual: ${actual}°C`
    }

    this.showAnimation = true
    clearInterval(this.timer)

    setTimeout(() => {
      if (this.round >= this.maxRounds) {
        this.gameOver = true
      } else {
        this.nextRound()
      }
    }, 2000)
  }

  nextRound() {
    this.currentIndex = (this.currentIndex + 1) % this.cities.length
    this.round += 1
    this.showAnimation = false
    this.resultEmoji = ''
    this.startTimer()
  }

  node: Node | null | undefined = null;
  init(): void {
    this.backAnimator = this.getUIContext().createAnimator(Constants.ANIMATION_OPTION);
    this.backAnimator.onFrame = () => {
      if (this.scene?.animations[0]) {
        this.animationEnabled = this.scene.animations[0].enabled;
        this.animationDuration = this.scene.animations[0].duration;
        this.animationIsRunning = this.scene.animations[0].running;
        this.progressValue = this.scene.animations[0].progress;
      }
    }
    if (this.scene === null) {
      Scene.load($rawfile('gltf/flower/scene.gltf'))
        .then(async (result: Scene) => {
          this.scene = result;
          let rf: SceneResourceFactory = this.scene.getResourceFactory();
          this.scene.environment.backgroundType = EnvironmentBackgroundType.BACKGROUND_NONE;

          if (this.scene && this.scene.root) {
            const node = this.scene.root.getNodeByPath('Sketchfab_Scene/Sketchfab_model/root/GLTF_SceneRootNode');
            if (node) {
              const angle = Math.PI / 6;
              node.rotation = { x: Math.sin(angle / 2), y: 0, z: 0, w: Math.cos(angle / 2) };
            } else {
              console.error('Node cannot find!');
            }
          }

          // Get animation resources
          this.anim = this.scene.animations[0];
          this.anim.start()
          if (this.anim) {
            this.anim.enabled = true;
            // Register callback function
            this.anim.onStarted(() => {
              Logger.info('onStarted');
              this.animationCallbackInvoked = 'animation on start';
            });

            this.anim.onFinished(() => {
              Logger.info('onFinished');
              this.animationCallbackInvoked = 'animation on finish';
            });

            Logger.info('ready to create a new animation.');
          } else {
            Logger.error('No animation found in scene.');
          }

          // create a new camera.
          this.cam = await rf.createCamera({ 'name': 'Camera' });
          // set the camera.
          this.cam.enabled = true;
          //this.cam.position.z = 5;
          this.cam.clearColor  = {r: 1, g: 1, b: 1, a: 1} as Color;

          this.sceneOpt = { scene: this.scene, modelType: ModelType.SURFACE } as SceneOptions;
        })
        .catch((error: string) => {
          Logger.error(`init error: ${error}`);
        });
    }
  }

  build() {
    if (this.gameOver) {
      Stack() {
        if (this.score >= 3) {
          Column() {
            if (this.sceneOpt) {
              Component3D(this.sceneOpt)
                .renderWidth($r('app.string.sixty_percent'))
                .renderHeight($r('app.string.sixty_percent'))
                .backgroundColor(Color.Transparent)
                .onAppear(() => {
                  if (!this.scene || !this.scene.animations[0]) {
                    return;
                  }
                  let anim: Animation = this.scene.animations[0];
                  anim.onStarted(() => {
                    this.animationCallbackInvoked = Constants.STRING_START;
                  });
                  anim.onFinished(() => {
                    this.animationCallbackInvoked = Constants.STRING_FINISH;
                  });
                  this.backAnimator?.play();
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
            Text('Congratulations!')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Green)
          } else {
            Text('Game Over!')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Red)
          }
          Text(`Correct Predictions: ${this.correctGuesses}`)
            .fontSize(20)
            .fontColor(Color.Gray)
          Text(`Total Point: ${this.score}`)
            .fontSize(20)
            .fontColor(Color.Gray)
          Button('Return Home')
            .onClick(() => {
              this.onJumpClick('pages/HomeScreen');
              this.currentIndex = 0
              this.guessTemp = 20
              this.score = 0
              this.timeLeft = 10
              this.resultEmoji = ''
              this.showAnimation = false
              this.round = 1
              this.gameOver = false
              this.correctGuesses = 0
            })
            .fontSize(12)
            .width('50%')
            .height(24)
            .borderRadius(14)
            .margin({ top: 10 })
            .backgroundColor(0x007AFF)
            .fontColor(Color.White)
        }.alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      }

    } else {
      Column({ space: 10 }) {
        Text(this.cities[this.currentIndex].name)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
          .fontColor(Color.Black)

        if (!this.showAnimation) {
          Text(`⏱ ${this.timeLeft} sec`)
            .fontSize(16)
            .fontColor(Color.Gray)

          Text(`${this.guessTemp}°C`)
            .fontSize(24)
            .fontColor(Color.Blue)
            .margin({ top: 4 })

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

          Button('Guess')
            .onClick(() => this.showResult(true))
            .margin({ top: 2 })
        } else {
          Text(this.resultEmoji)
            .fontSize(20)
            .fontColor(Color.Gray)
        }

        Text(`Score: ${this.score}`)
          .fontSize(18)
          .margin({ top: 15 })
          .fontColor(Color.Gray)
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
  }
}
