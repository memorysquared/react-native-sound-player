package com.johnsonsu.rnsoundplayer;

import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.MediaPlayer.OnPreparedListener;
import android.net.Uri;

import java.io.File;

import java.io.IOException;
import javax.annotation.Nullable;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.LifecycleEventListener;
import java.util.Map;
import java.util.HashMap;


public class RNSoundPlayerModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

  public final static String EVENT_SETUP_ERROR = "OnSetupError";
  public final static String EVENT_FINISHED_PLAYING = "FinishedPlaying";
  public final static String EVENT_FINISHED_LOADING = "FinishedLoading";
  public final static String EVENT_FINISHED_LOADING_FILE = "FinishedLoadingFile";
  public final static String EVENT_FINISHED_LOADING_URL = "FinishedLoadingURL";

  private final ReactApplicationContext reactContext;
  private float volume;
  private AudioManager audioManager;
  private HashMap<String, MediaPlayer> mediaPlayers;

  public RNSoundPlayerModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    this.volume = 1.0f;
    this.audioManager = (AudioManager) this.reactContext.getSystemService(Context.AUDIO_SERVICE);
    this.mediaPlayers = new HashMap<>(); // store multiple media players
    reactContext.addLifecycleEventListener(this);
  }

  @Override
  public String getName() {
    return "RNSoundPlayer";
  }

  @ReactMethod
  public void setSpeaker(Boolean on) {
    audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
    audioManager.setSpeakerphoneOn(on);
  }

  @Override
  public void onHostResume() {
  }

  @Override
  public void onHostPause() {
  }

  @Override
  public void onHostDestroy() {
    for (Map.Entry<String, MediaPlayer> entry : this.mediaPlayers.entrySet()) {
        MediaPlayer player = entry.getValue();
        if (player != null) {
            player.stop();
            player.release();
        }
    }
    this.mediaPlayers.clear();
  }

  @ReactMethod
  public void playSoundFile(String name, String type, String key) throws IOException {
    mountSoundFile(name, type, key);
    this.resume(key);
  }

  @ReactMethod
  public void loadSoundFile(String name, String type, String key) throws IOException {
    mountSoundFile(name, type, key);
  }

  @ReactMethod
  public void playUrl(String url, String key) throws IOException {
    prepareUrl(url, key);
    this.resume(key);
  }

  @ReactMethod
  public void loadUrl(String url, String key) throws IOException {
    prepareUrl(url, key);
  }

  @ReactMethod
  public void pause(String key) throws IllegalStateException {
      MediaPlayer player = this.mediaPlayers.get(key);
      if (player != null && player.isPlaying()) {
          player.pause();
      }
  }

  @ReactMethod
  public void resume(String key) throws IOException, IllegalStateException {
    MediaPlayer player = this.mediaPlayers.get(key);
    if (player != null) {
      this.setVolume(this.volume, key);
      player.start();
    }
  }

  @ReactMethod
  public void stop(String key) throws IllegalStateException {
    MediaPlayer player = this.mediaPlayers.get(key);
    if (player != null) {
      player.stop();
    }
  }

  @ReactMethod
  public void seek(float seconds, String key) throws IllegalStateException {
    MediaPlayer player = this.mediaPlayers.get(key);
    if (player != null) {
      player.seekTo((int) seconds * 1000);
    }
  }

  @ReactMethod
  public void setVolume(float volume, String key) throws IOException {
    this.volume = volume;
    MediaPlayer player = this.mediaPlayers.get(key);
    if (player != null) {
      player.setVolume(volume, volume);
    }
  }

  @ReactMethod
  public void getInfo(String key, Promise promise) {
    MediaPlayer player = this.mediaPlayers.get(key);
    if (player == null) {
      promise.resolve(null);
      return;
    }
    WritableMap map = Arguments.createMap();
    map.putDouble("currentTime", player.getCurrentPosition() / 1000.0);
    map.putDouble("duration", player.getDuration() / 1000.0);
    promise.resolve(map);
  }

  @ReactMethod
  public void setLooping(String key) throws IOException {
     MediaPlayer player = this.mediaPlayers.get(key);
     if (player != null) {
       //player.setLooping(true);
       player.setOnCompletionListener(mp -> {
           mp.seekTo(0);
           mp.start();
       });
     }
  }

  @ReactMethod
  public void addListener(String eventName) {
    // Set up any upstream listeners or background tasks as necessary
  }

  @ReactMethod
  public void removeListeners(Integer count) {
    // Remove upstream listeners, stop unnecessary background tasks
  }

  private void sendEvent(ReactApplicationContext reactContext,
                         String eventName,
                         @Nullable WritableMap params) {
    reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
  }

  private void mountSoundFile(String name, String type, String key) throws IOException {
    try {
      Uri uri;
      int soundResID = getReactApplicationContext().getResources().getIdentifier(name, "raw", getReactApplicationContext().getPackageName());

      if (soundResID > 0) {
        uri = Uri.parse("android.resource://" + getReactApplicationContext().getPackageName() + "/raw/" + name);
      } else {
        uri = this.getUriFromFile(name, type);
      }

      MediaPlayer mediaPlayer = mediaPlayers.get(key);
      if (mediaPlayer == null) {
          mediaPlayer = initializeMediaPlayer(uri);
          mediaPlayers.put(key, mediaPlayer);
      } else {
          mediaPlayer.reset();
          mediaPlayer.setDataSource(getCurrentActivity(), uri);
          mediaPlayer.prepare();
      }
      sendMountFileSuccessEvents(name, type);
    } catch (IOException e) {
      sendErrorEvent(e);
    }
  }

  private Uri getUriFromFile(String name, String type) {
    String folder = getReactApplicationContext().getFilesDir().getAbsolutePath();
    String file = (!type.isEmpty()) ? name + "." + type : name;

    // http://blog.weston-fl.com/android-mediaplayer-prepare-throws-status0x1-error1-2147483648
    // this helps avoid a common error state when mounting the file
    File ref = new File(folder + "/" + file);

    if (ref.exists()) {
      ref.setReadable(true, false);
    }

    return Uri.parse("file://" + folder + "/" + file);
  }

  private void prepareUrl(final String url, String key) throws IOException {
    try {
      MediaPlayer mediaPlayer = mediaPlayers.get(key);

      if (mediaPlayer == null) {
        Uri uri = Uri.parse(url);
        mediaPlayer = initializeMediaPlayer(uri);
        mediaPlayers.put(key, mediaPlayer);
        mediaPlayer.setOnPreparedListener(
                new OnPreparedListener() {
                  @Override
                  public void onPrepared(MediaPlayer mediaPlayer) {
                    WritableMap onFinishedLoadingURLParams = Arguments.createMap();
                    onFinishedLoadingURLParams.putBoolean("success", true);
                    onFinishedLoadingURLParams.putString("url", url);
                    sendEvent(getReactApplicationContext(), EVENT_FINISHED_LOADING_URL, onFinishedLoadingURLParams);
                  }
                }
        );
      } else {
        Uri uri = Uri.parse(url);
        mediaPlayer.reset();
        mediaPlayer.setDataSource(getCurrentActivity(), uri);
        mediaPlayer.prepare();
      }
      WritableMap params = Arguments.createMap();
      params.putBoolean("success", true);
      sendEvent(getReactApplicationContext(), EVENT_FINISHED_LOADING, params);
    } catch (IOException e) {
      WritableMap errorParams = Arguments.createMap();
      errorParams.putString("error", e.getMessage());
      sendEvent(getReactApplicationContext(), EVENT_SETUP_ERROR, errorParams);
    }
  }

  private MediaPlayer initializeMediaPlayer(Uri uri) throws IOException {
    MediaPlayer mediaPlayer = MediaPlayer.create(getCurrentActivity(), uri);

    if (mediaPlayer == null) {
      throw new IOException("Failed to initialize MediaPlayer for URI: " + uri.toString());
    }

    mediaPlayer.setOnCompletionListener(
            new OnCompletionListener() {
              @Override
              public void onCompletion(MediaPlayer arg0) {
                WritableMap params = Arguments.createMap();
                params.putBoolean("success", true);
                sendEvent(getReactApplicationContext(), EVENT_FINISHED_PLAYING, params);
              }
            }
    );

    return mediaPlayer;
  }

  private void sendMountFileSuccessEvents(String name, String type) {
    WritableMap params = Arguments.createMap();
    params.putBoolean("success", true);
    sendEvent(reactContext, EVENT_FINISHED_LOADING, params);

    WritableMap onFinishedLoadingFileParams = Arguments.createMap();
    onFinishedLoadingFileParams.putBoolean("success", true);
    onFinishedLoadingFileParams.putString("name", name);
    onFinishedLoadingFileParams.putString("type", type);
    sendEvent(reactContext, EVENT_FINISHED_LOADING_FILE, onFinishedLoadingFileParams);
  }


  private void sendErrorEvent(IOException e) {
    WritableMap errorParams = Arguments.createMap();
    errorParams.putString("error", e.getMessage());
    sendEvent(reactContext, EVENT_SETUP_ERROR, errorParams);
  }
}
