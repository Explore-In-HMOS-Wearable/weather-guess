import { Color, Vec4 } from '@kit.ArkGraphics3D';
import { AnimatorOptions } from '@kit.ArkUI';

export class Constants {
  /**
   * Full percent.
   */
  static readonly FULL_PERCENT: string = '100%';

  /**
   * Ninety percent.
   */
  static readonly NINETY_PERCENT: string = '90%';

  /**
   * Thirty percent.
   */
  static readonly THIRTY_PERCENT: string = '30%';

  /**
   * Twenty five percent.
   */
  static readonly TWENTY_FIVE_PERCENT: string = '25%'

  /**
   * Twenty percent.
   */
  static readonly TWENTY_PERCENT: string = '20%';

  /**
   * Thirteen percent.
   */
  static readonly THIRTEEN_PERCENT: string = '13%';

  /**
   * List space.
   */
  static readonly LIST_SPACE: number = 12;

  /**
   * Camera position z index.
   */
  static readonly CAMERA_POSITION_Z_INDEX: number = 5;

  /**
   * Font weight 500.
   */
  static readonly FONT_WEIGHT_FIVE_HUNDRED: number = 500;

  /**
   * Clear color (transparent).
   */
  static readonly CLEAR_COLOR: Color = {
    r: 0,
    g: 0,
    b: 0,
    a: 0.0
  };

  /**
   * PI RADIAN.
   */
  static readonly PI_RADIAN: number = 180;

  /**
   * Degree 45.
   */
  static readonly DEGREE_FORTY_FIVE: number = 45;

  /**
   * Degree 60.
   */
  static readonly DEGREE_SIXTY: number = 60;

  /**
   * Degree 90.
   */
  static readonly DEGREE_NINETY: number = 90;

  /**
   * Half hundred.
   */
  static readonly HALF_HUNDRED: number = 50.0;

  /**
   * Animation option for the backAnimator driving 3D scene frame progress.
   */
  static readonly ANIMATION_OPTION: AnimatorOptions = {
    duration: 2000,
    easing: 'ease',
    delay: 0,
    fill: 'none',
    direction: 'normal',
    iterations: -1,
    begin: 100,
    end: 200
  };

  /**
   * String no.
   */
  static readonly STRING_NO: string = 'no';

  /**
   * String start.
   */
  static readonly STRING_START: string = 'start';

  /**
   * String finish.
   */
  static readonly STRING_FINISH: string = 'finish';

  /**
   * Environment factor presets for ArkGraphics3D scene environment.
   */
  static readonly ENVIRONMENT_FACTOR: Vec4[] = [
    {
      x: 1,
      y: 1,
      z: 1,
      w: 1
    },
    {
      x: 40,
      y: 1,
      z: 1,
      w: 1
    },
    {
      x: 1,
      y: 40,
      z: 1,
      w: 1
    },
    {
      x: 1,
      y: 1,
      z: 40,
      w: 1
    }
  ];

  /**
   * Background color.
   */
  static readonly BACKGROUND_COLOR: string = '#F1F3F5'
}
