import { Animation, Scene, Camera, EnvironmentBackgroundType, SceneResourceFactory, Color } from '@kit.ArkGraphics3D';
import { router, AnimatorResult } from '@kit.ArkUI';
import Logger from '../utils/Logger';
import { Constants } from '../constants/Constants';
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
export struct HomeScreen {
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

  onJumpClick(target_url: string): void {
    this.getUIContext().getRouter().pushUrl({ url: target_url }, router.RouterMode.Single, (err) => {
      if (err) {
        Logger.error('TAG', `Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
    });
  }

  onShake() {
    console.info('Watch shook!');
  }

  aboutToAppear(): void {
    this.isNewGame = true
    this.init()
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        const x = data.x;
        const y = data.y;
        const z = data.z;

        const acceleration = Math.sqrt(x * x + y * y + z * z);
        const delta = Math.abs(acceleration - 9.8);

        if (delta > this.SHAKE_THRESHOLD) {
          this.onShake()
          this.onJumpClick('pages/GameScreen');
        }
      }, { interval: 100000000 }); // 100 ms

    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`Accelerometer cannot listen. Code: ${e.code}, message: ${e.message}`);
    }
  }

  onPageHide(): void {
    if (this.scene) {
      this.scene.destroy();
    }

    this.cam = null;
    this.scene = null;
  }

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
      Scene.load($rawfile('gltf/earth/scene.gltf'))
        .then(async (result: Scene) => {
          this.scene = result;
          let rf: SceneResourceFactory = this.scene.getResourceFactory();
          this.scene.environment.backgroundType = EnvironmentBackgroundType.BACKGROUND_NONE;

          this.anim = this.scene.animations[0];
          this.anim.start()
          if (this.anim) {
            this.anim.enabled = true;
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

          this.cam = await rf.createCamera({ 'name': 'Camera' });
          this.cam.enabled = true;
          this.cam.clearColor = {
            r: 1,
            g: 1,
            b: 1,
            a: 1
          } as Color;

          this.sceneOpt = { scene: this.scene, modelType: ModelType.SURFACE } as SceneOptions;
        })
        .catch((error: string) => {
          Logger.error(`init error: ${error}`);
        });
    }
  }

  build() {
    Stack() {
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

      Text('WEATHER GUESS')
        .fontWeight(FontWeight.Bolder)
        .fontSize(20)

      if (this.isNewGame === true) {
        Column() {
          Image($r('app.media.watch'))
            .width(20)
            .height(20)
          Text('Wave your hand to start game!')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
            .textAlign(TextAlign.Center)
            .width('100%')

          Button('OK')
            .onClick(() => {
              this.isNewGame = false
            })
            .fontSize(10)
            .width(85)
            .height(22)
            .borderRadius(14)
            .margin({ top: 8 })
            .backgroundColor(0x007AFF)
            .fontColor(Color.White)
        }
        .width(150)
        .height(120)
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(10)
        .alignSelf(ItemAlign.Center)
      }
    }
    .width(Constants.FULL_PERCENT)
    .height(Constants.FULL_PERCENT)
    .alignContent(Alignment.Center)

  }
}