import { Injectable } from '@angular/core';
import { Cordova, IonicNativePlugin, Plugin } from '@ionic-native/core';

/**
 * @name SimpleVideoRecorder
 * @description
 * A simple video recorder without retake and review options.
 *
 * @interfaces
 * SimpleVideoRecorderStartupOptions
 */

export interface SimpleVideoRecorderOptions {
  option?: any;
}

@Plugin({
  pluginName: 'SimpleVideoRecorder',
  plugin: 'cordova-plugin-simple-video-recorder',
  pluginRef: 'SimpleVideoRecorder',
  repo: 'https://github.com/manuklapf/cordova-plugin-simple-video-recorder',
  platforms: ['iOS'],
})
@Injectable()
export class SimpleVideoRecorder extends IonicNativePlugin {
  /**
   * Starts SimpleVideoRecorder.
   * @param {SimpleVideoRecorder} options
   * @return {Promise<any>}
   */
  @Cordova({
    successIndex: 1,
    errorIndex: 2,
  })


  startPlugin(options: SimpleVideoRecorderOptions): Promise<any> {
    return;
  }

  /**
   * Stops the camera preview instance. (iOS)
   * @return {Promise<any>}
   */
  @Cordova()
  stopCamera(): Promise<any> {
    return;
  }

  /**
   * Switch from the rear camera and front camera, if available.
   * @return {Promise<any>}
   */
  @Cordova()
  switchCamera(): Promise<any> {
    return;
  }

  /**
   * Switch the flash mode.
   * @return {Promise<any>}
   */
  @Cordova()
  switchFlash(): Promise<any> {
    return;
  }

  /**
   * Start the video capture
   * @return {Promise<any>}
   */
  @Cordova()
  startVideoCapture(): Promise<any> {
    return;
  }

  /**
   * Stops the video capture
   * @return {Promise<any>}
   */
  @Cordova({
    successIndex: 0,
    errorIndex: 1
  })
  stopVideoCapture(): Promise<any> {
    return;
  }

  /**
   * Promise of the recordingTimer.
   * @return {Promise<any>}
   */
  @Cordova({
    successIndex : 0,
    errorIndex : 1,
  })
  recordingTimer(): Promise<any> {
    return;
  }
}
