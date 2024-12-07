declare module "react-native-sound-player" {
  import { EmitterSubscription } from "react-native";

  export type SoundPlayerEvent =
      | "OnSetupError"
      | "FinishedLoading"
      | "FinishedPlaying"
      | "FinishedLoadingURL"
      | "FinishedLoadingFile";

  export type SoundPlayerEventData = {
    success?: boolean;
    url?: string;
    name?: string;
    type?: string;
  };

  interface SoundPlayerType {
    playSoundFile: (name: string, type: string, key?: string) => void;
    playSoundFileWithDelay: (
        name: string,
        type: string,
        delay: number,
        key: string
    ) => void;
    loadSoundFile: (name: string, type: string, key?: string) => void;
    playUrl: (url: string, key?: string) => void;
    loadUrl: (url: string, key?: string) => void;
    playAsset: (asset: number, key?: string) => void;
    loadAsset: (asset: number, key?: string) => void;
    /** @deprecated  please use addEventListener */
    onFinishedPlaying: (
        key: string,
        callback: (success: boolean) => unknown
    ) => void;
    /** @deprecated  please use addEventListener */
    onFinishedLoading: (
        key: string,
        callback: (success: boolean) => unknown
    ) => void;
    /** Subscribe to any event. Returns a subscription object. Subscriptions created by this function cannot be removed by calling unmount(). You NEED to call yourSubscriptionObject.remove() when you no longer need this event listener or whenever your component unmounts. */
    addEventListener: (
        eventName: SoundPlayerEvent,
        callback: (data: SoundPlayerEventData) => void
    ) => EmitterSubscription;
    /** Play the loaded sound file. This function is the same as `resume`. */
    play: (key?: string) => void;
    /** Pause the currently playing file. */
    pause: (key?: string) => void;
    /** Resume from pause and continue playing the same file. This function is the same as `play`. */
    resume: (key?: string) => void;
    /** Stop playing, call `playSound` to start playing again. */
    stop: (key?: string) => void;
    /** Seek to seconds of the currently playing file. */
    seek: (seconds: number, key?: string) => void;
    /** Set the volume of the current player. This does not change the volume of the device. */
    setVolume: (volume: number, key?: string) => void;
    /** Only available on iOS. Overwrite default audio output to speaker, which forces playUrl() function to play from speaker. */
    setSpeaker: (on: boolean, key?: string) => void;
    /** Only available on iOS. If you set this option, your audio will be mixed with audio playing in background apps, such as the Music app. */
    setMixAudio: (on: boolean, key?: string) => void;
    /** IOS only. Set the number of loops. A negative value will loop indefinitely until the stop() command is called. */
    setNumberOfLoops: (loops: number, key?: string) => void;
    /** Get the currentTime and duration of the currently mounted audio media. This function returns a promise which resolves to an Object containing currentTime and duration properties. */
    getInfo: (key?: string) => Promise<{ currentTime: number; duration: number }>;
    /** @deprecated Please use addEventListener and remove your own listener by calling yourSubscriptionObject.remove(). */
    unmount: () => void;
  }

  const SoundPlayer: SoundPlayerType;

  export default SoundPlayer;
}
