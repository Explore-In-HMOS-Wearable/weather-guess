// Type-only imports: erased at compile time, do NOT trigger runtime module
// loading. This lets us annotate fields with proper types while avoiding the
// hard SyntaxError that a value import of `Scene` causes on emulator
// (libscene.z.so is absent there).
import type { Animation, Camera, Light, Scene, SceneResourceFactory } from '@kit.ArkGraphics3D';
import { AnimatorResult, AnimatorOptions } from '@kit.ArkUI';
import Logger from './Logger';

/**
 * SceneController encapsulates the ArkGraphics3D scene lifecycle shared by
 * HomeScreen (earth model) and GameScreen (flower model).
 *
 * ArkGraphics3D is only available on real hardware. On emulator the native
 * library is absent; a static value import of `Scene` would throw a hard
 * SyntaxError at module-load time. We use a dynamic import() so the missing
 * library is a recoverable warning and the rest of the UI still renders.
 *
 * Usage:
 *   1. Construct with the GLTF raw-file path and an AnimatorOptions value.
 *   2. Call init(getUIContext()) in aboutToAppear() / init().
 *   3. Bind sceneOpt to Component3D.
 *   4. Call destroy() in onPageHide() before nulling references.
 */
export class SceneController {
  private gltfPath: ResourceStr;
  private animatorOptions: AnimatorOptions;
  private onReadyCallback: ((sceneOpt: SceneOptions) => void) | null = null;

  scene: Scene | null = null;
  cam: Camera | null = null;
  backAnimator: AnimatorResult | undefined = undefined;
  anim: Animation | null = null;

  constructor(gltfPath: ResourceStr, animatorOptions: AnimatorOptions) {
    this.gltfPath = gltfPath;
    this.animatorOptions = animatorOptions;
  }

  /**
   * Registers a callback invoked once the scene and camera are ready.
   * The caller receives the SceneOptions to assign to @State sceneOpt.
   */
  onReady(callback: (sceneOpt: SceneOptions) => void): void {
    this.onReadyCallback = callback;
  }

  /**
   * Initialises the backAnimator and loads the GLTF scene.
   * @param uiContext obtained via getUIContext() in the component.
   */
  init(uiContext: UIContext): void {
    this.backAnimator = uiContext.createAnimator(this.animatorOptions);
    this.backAnimator.onFrame = () => {
      // Frame tracking — callers can override backAnimator.onFrame after init()
    };

    if (this.scene !== null) {
      return;
    }

    // Dynamic import so that a missing native library on emulator is a
    // recoverable error rather than a fatal startup SyntaxError.
    import('@kit.ArkGraphics3D')
      .then(async (mod) => {
        // `typeof` in type positions is banned by arkts-no-type-query; drop the
        // cast and rely on inference from the module's own type declarations.
        const sceneClass = mod.Scene;
        const environmentBackgroundType = mod.EnvironmentBackgroundType;

        if (!sceneClass) {
          Logger.warn('SceneController: ArkGraphics3D Scene not available on this device');
          return;
        }

        // ArkTS requires explicit try-catch for every awaited call that may throw.
        try {
          const result: Scene = await sceneClass.load(this.gltfPath) as Scene;
          this.scene = result;
          const rf: SceneResourceFactory = this.scene.getResourceFactory() as SceneResourceFactory;
          this.scene.environment.backgroundType = environmentBackgroundType.BACKGROUND_NONE;

          this.anim = this.scene.animations[0] as Animation;
          if (this.anim) {
            this.anim.enabled = true;
            this.anim.start();
            this.anim.onStarted(() => {
              Logger.info('SceneController: animation started');
            });
            this.anim.onFinished(() => {
              Logger.info('SceneController: animation finished');
            });
          } else {
            Logger.error('SceneController: no animation found in scene');
          }

          this.cam = await rf.createCamera({ 'name': 'Camera' }) as Camera;
          this.cam.enabled = true;
          this.cam.clearColor = { r: 0, g: 0, b: 0, a: 0 };

          // Pull camera back from the unit-sphere earth at origin.
          // Inner try-catch: a failure here must NOT prevent onReadyCallback
          // from being called — that would leave Component3D with a null scene.
          try {
            this.cam.position = { x: 0, y: 0, z: 5 };
          } catch (posErr) {
            Logger.warn(`SceneController: cam.position setter failed: ${(posErr as Error).message}`);
          }

          // The earth GLTF material is only 2% emissive — invisible without a
          // light. createLight() is also guarded so it cannot block the callback.
          try {
            const lightTypeEnum = mod.LightType;
            const light: Light = await rf.createLight({ name: 'MainLight' }, lightTypeEnum.DIRECTIONAL) as Light;
            light.enabled = true;
            light.color = { r: 1, g: 1, b: 1, a: 1 };
            light.intensity = 2.0;
            light.position = { x: 0, y: 5, z: 5 };
          } catch (lightErr) {
            Logger.warn(`SceneController: createLight failed: ${(lightErr as Error).message}`);
          }

          const sceneOpt: SceneOptions = { scene: this.scene, modelType: ModelType.SURFACE } as SceneOptions;
          if (this.onReadyCallback) {
            this.onReadyCallback(sceneOpt);
          }
        } catch (e) {
          Logger.error(`SceneController: scene load failed: ${(e as Error).message}`);
        }
      })
      .catch((error: Error) => {
        Logger.warn(`SceneController: ArkGraphics3D unavailable (emulator?): ${error.message}`);
      });
  }

  /**
   * Stops the animator and destroys the scene. Call in onPageHide().
   */
  destroy(): void {
    this.backAnimator?.cancel();
    if (this.scene) {
      this.scene.destroy();
    }
    this.cam = null;
    this.scene = null;
    this.anim = null;
  }
}
