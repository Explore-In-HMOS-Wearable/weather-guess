import { Animation } from '@kit.ArkGraphics3D';
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { NavigationService } from '../services/NavigationService';
import { Constants } from '../constants/Constants';
import { SceneController } from '../utils/SceneController';

@Component
export struct HomeScreen {
  @State sceneOpt: SceneOptions | null = null;
  @State difficulty: number = 1;
  @State isDailyMode: boolean = false;
  private readonly SHAKE_THRESHOLD: number = 12;
  private sensorCallback: ((data: sensor.AccelerometerResponse) => void) | null = null;
  private sceneCtrl: SceneController = new SceneController(
    $rawfile('gltf/earth/scene.gltf'),
    Constants.ANIMATION_OPTION
  );

  navigationService: NavigationService = NavigationService.getInstance();

  onShake() {
    console.info('Watch shook!');
  }

  aboutToAppear(): void {
    this.init()
    try {
      this.sensorCallback = (data: sensor.AccelerometerResponse) => {
        const x = data.x;
        const y = data.y;
        const z = data.z;

        const acceleration = Math.sqrt(x * x + y * y + z * z);
        const delta = Math.abs(acceleration - 9.8);

        if (delta > this.SHAKE_THRESHOLD) {
          this.onShake()
          this.navigationService.difficulty = this.difficulty
          this.navigationService.isDailyMode = this.isDailyMode
          this.navigationService.pageInfos.pushPath({ name: 'Game' })
        }
      };
      sensor.on(sensor.SensorId.ACCELEROMETER, this.sensorCallback, { interval: 100000000 }); // 100 ms

    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`Accelerometer cannot listen. Code: ${e.code}, message: ${e.message}`);
    }
  }

  onPageHide(): void {
    if (this.sensorCallback) {
      try {
        sensor.off(sensor.SensorId.ACCELEROMETER, this.sensorCallback);
      } catch (e) {
        // ignore if callback was not registered
      }
      this.sensorCallback = null;
    }
    this.sceneCtrl.destroy();
    this.sceneOpt = null;
  }

  init(): void {
    this.sceneCtrl.onReady((opt: SceneOptions) => {
      this.sceneOpt = opt;
    });
    this.sceneCtrl.init(this.getUIContext());
  }

  build() {
    Stack() {
      Column() {
        if (this.sceneOpt) {
          Component3D(this.sceneOpt)
            .renderWidth($r('app.string.full_percent_str'))
            .renderHeight($r('app.string.full_percent_str'))
            .backgroundColor(Color.Transparent)
            .onAppear(() => {
              if (!this.sceneCtrl.scene || !this.sceneCtrl.scene.animations[0]) {
                return;
              }
              let anim: Animation = this.sceneCtrl.scene.animations[0];
              anim.onStarted(() => {
                console.info('HomeScreen: animation started');
              });
              anim.onFinished(() => {
                console.info('HomeScreen: animation finished');
              });
              this.sceneCtrl.backAnimator?.play();
            })
        } else {
          // Emulator / no-GPU fallback: static globe placeholder.
          // ArkGraphics3D is absent on the wearable emulator (no libscene.z.so).
          Text('🌍')
            .fontSize(90)
            .opacity(0.18)
        }
      }
      .width(Constants.FULL_PERCENT)
      .height(Constants.FULL_PERCENT)
      .borderRadius($r('app.float.board_radius_normal'))
      .justifyContent(FlexAlign.Center)

      Column({ space: 6 }) {
        Text($r('app.string.app_title'))
          .fontWeight(FontWeight.Bolder)
          .fontSize(18)
          .fontColor(Color.Black)

        Button($r('app.string.btn_start'))
          .onClick(() => {
            this.navigationService.difficulty = this.difficulty
            this.navigationService.isDailyMode = this.isDailyMode
            this.navigationService.pageInfos.pushPath({ name: 'Game' })
          })
          .fontSize(14)
          .width('46%')
          .height(32)
          .borderRadius(16)
          .backgroundColor(0x007AFF)
          .fontColor(Color.White)

        // Difficulty selector (P2-T3)
        Row({ space: 6 }) {
          Button($r('app.string.difficulty_easy'))
            .onClick(() => { this.difficulty = 0 })
            .fontSize(11)
            .layoutWeight(1)
            .height(28)
            .borderRadius(14)
            .padding({ top: 0, bottom: 0, left: 4, right: 4 })
            .backgroundColor(this.difficulty === 0 ? 0x22AA44 : 0xCCCCCC)
            .fontColor(Color.White)
          Button($r('app.string.difficulty_normal'))
            .onClick(() => { this.difficulty = 1 })
            .fontSize(11)
            .layoutWeight(1)
            .height(28)
            .borderRadius(14)
            .padding({ top: 0, bottom: 0, left: 4, right: 4 })
            .backgroundColor(this.difficulty === 1 ? 0x007AFF : 0xCCCCCC)
            .fontColor(Color.White)
          Button($r('app.string.difficulty_hard'))
            .onClick(() => { this.difficulty = 2 })
            .fontSize(11)
            .layoutWeight(1)
            .height(28)
            .borderRadius(14)
            .padding({ top: 0, bottom: 0, left: 4, right: 4 })
            .backgroundColor(this.difficulty === 2 ? 0xCC3333 : 0xCCCCCC)
            .fontColor(Color.White)
        }
        .width('80%')

        // Daily Challenge toggle (P4-T4)
        Button(this.isDailyMode ? $r('app.string.daily_mode_on') : $r('app.string.daily_mode_off'))
          .onClick(() => { this.isDailyMode = !this.isDailyMode })
          .fontSize(10)
          .width(110)
          .height(20)
          .borderRadius(10)
          .backgroundColor(this.isDailyMode ? 0xAA7700 : 0xCCCCCC)
          .fontColor(Color.White)
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 12 })
      .position({ x: '50%', y: '72%' })
      .translate({ x: '-50%', y: '-50%' })
    }
    .width(Constants.FULL_PERCENT)
    .height(Constants.FULL_PERCENT)
    .alignContent(Alignment.Center)
    .backgroundColor(Color.White)
  }
}
