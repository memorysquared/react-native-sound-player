/**
 * @flow
 */
"use strict";

import { NativeModules, NativeEventEmitter, Platform } from "react-native";
import resolveAsset from 'react-native/Libraries/Image/resolveAssetSource';
const { RNSoundPlayer } = NativeModules;

const _soundPlayerEmitter = new NativeEventEmitter(RNSoundPlayer);
let _finishedPlayingListener = null;
let _finishedLoadingListener = null;

const _soundPlayerDefaultKey = "soundPlayerDefaultKey";

export default {
  playSoundFile: (name: string, type: string, key: string) => {
    RNSoundPlayer.playSoundFile(name, type, key || _soundPlayerDefaultKey);
  },

  playSoundFileWithDelay: (name: string, type: string, delay: number, key: string) => {
    RNSoundPlayer.playSoundFileWithDelay(name, type, delay, key || _soundPlayerDefaultKey);
  },

  loadSoundFile: (name: string, type: string, key: string) => {
    RNSoundPlayer.loadSoundFile(name, type, key || _soundPlayerDefaultKey);
  },

  setNumberOfLoops: (loops: number, key: string) => {
    RNSoundPlayer.setNumberOfLoops(loops, key || _soundPlayerDefaultKey);
  },

  playUrl: (url: string, key: string) => {
    RNSoundPlayer.playUrl(url, key || _soundPlayerDefaultKey);
  },

  loadUrl: (url: string, key: string) => {
    RNSoundPlayer.loadUrl(url, key || _soundPlayerDefaultKey);
  },

  playAsset: async (asset: number, key: string) => {
    if (!(__DEV__) && Platform.OS === "android") {
      RNSoundPlayer.playSoundFile(resolveAsset(asset).uri, '', key || _soundPlayerDefaultKey);
    } else {
      RNSoundPlayer.playUrl(resolveAsset(asset).uri, key || _soundPlayerDefaultKey);
    }
  },

  loadAsset: (asset: number, key: string) => {
    if (!(__DEV__) && Platform.OS === "android") {
      RNSoundPlayer.loadSoundFile(resolveAsset(asset).uri, '', key || _soundPlayerDefaultKey);
    } else {
      RNSoundPlayer.loadUrl(resolveAsset(asset).uri, key || _soundPlayerDefaultKey);
    }
  },

  onFinishedPlaying: (callback: (success: boolean) => any) => {
    if (_finishedPlayingListener) {
      _finishedPlayingListener.remove();
      _finishedPlayingListener = undefined;
    }

    _finishedPlayingListener = _soundPlayerEmitter.addListener(
        "FinishedPlaying",
        callback
    );
  },

  onFinishedLoading: (callback: (success: boolean) => any) => {
    if (_finishedLoadingListener) {
      _finishedLoadingListener.remove();
      _finishedLoadingListener = undefined;
    }

    _finishedLoadingListener = _soundPlayerEmitter.addListener(
        "FinishedLoading",
        callback
    );
  },

  addEventListener: (
      eventName:
          | "OnSetupError"
              | "FinishedLoading"
              | "FinishedPlaying"
              | "FinishedLoadingURL"
              | "FinishedLoadingFile",
      callback: Function
  ) => _soundPlayerEmitter.addListener(eventName, callback),

  play: (key: string) => {
    // play and resume has the exact same implementation natively
    RNSoundPlayer.resume(key || _soundPlayerDefaultKey);
  },

  pause: (key: string) => {
    RNSoundPlayer.pause(key || _soundPlayerDefaultKey);
  },

  resume: (key: string) => {
    RNSoundPlayer.resume(key || _soundPlayerDefaultKey);
  },

  stop: (key: string) => {
    RNSoundPlayer.stop(key || _soundPlayerDefaultKey);
  },

  seek: (seconds: number, key: string) => {
    RNSoundPlayer.seek(seconds, key || _soundPlayerDefaultKey);
  },

  setVolume: (volume: number, key: string) => {
    RNSoundPlayer.setVolume(volume, key || _soundPlayerDefaultKey);
  },

  setSpeaker: (on: boolean, key: string) => {
    RNSoundPlayer.setSpeaker(on, key || _soundPlayerDefaultKey);
  },

  setMixAudio: (on: boolean, key: string) => {
    if (Platform.OS === "android") {
      console.log("setMixAudio is not implemented on Android");
    } else {
      RNSoundPlayer.setMixAudio(on, key || _soundPlayerDefaultKey);
    }
  },

  getInfo: async (key: string) => RNSoundPlayer.getInfo(key || _soundPlayerDefaultKey),

  unmount: () => {
    if (_finishedPlayingListener) {
      _finishedPlayingListener.remove();
      _finishedPlayingListener = undefined;
    }

    if (_finishedLoadingListener) {
      _finishedLoadingListener.remove();
      _finishedLoadingListener = undefined;
    }
  },
};
