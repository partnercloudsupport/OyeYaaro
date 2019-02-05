package com.plmlogix.connectyaar;

import android.os.Bundle;

import android.annotation.TargetApi;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Environment;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.vincent.videocompressor.VideoCompress;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "plmlogix.recordvideo/info";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        //Create OyeYaaro Directory in SD Card, if it's not exists
        File rootDir = new File(Environment.getExternalStorageDirectory().getAbsoluteFile() + "/OyeYaaro");
        if (!rootDir.exists() || !rootDir.isDirectory()) {
            rootDir.mkdir();
        }

        //Create Videos Directory in SD Card/OyeYaaro, if it's not exists
        File videoDir = new File(rootDir.getAbsolutePath() + "/Videos");
        if (!videoDir.exists() || !videoDir.isDirectory()) {
            videoDir.mkdir();
        }

        //Create .nomedia File in Video Directory, if it's not exists
        File noMediaFile = new File(videoDir.getAbsolutePath() + "/.nomedia");
        if (!noMediaFile.exists() || !noMediaFile.isFile()) {
            try {
                noMediaFile.createNewFile();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, final MethodChannel.Result result) {

                final Map<String, Object> arguments = methodCall.arguments();

                if (methodCall.method.equals("compressVideo")) {
                    final String originalVideoUrl = (String) arguments.get("originalVideoUrl");
                    String outDir = Environment.getExternalStorageDirectory().getAbsoluteFile() + "/OyeYaaro" + "/Videos";
                    final String destPath = outDir + File.separator + "VID_" + new SimpleDateFormat("yyyyMMdd_HHmmss", getLocale()).format(new Date()) + ".mp4";
                    VideoCompress.compressVideoMedium(originalVideoUrl, destPath, new VideoCompress.CompressListener() {
                        @Override
                        public void onStart() {
                        }

                        @Override
                        public void onSuccess() {
                          try{
                            File originalFile = new File(originalVideoUrl);
                            if(originalFile.exists()){
                              originalFile.delete();
                              System.out.println("File Deleted: "+originalFile.getPath());
                            }
                          }catch(Error error){
                            System.out.println(error);
                          }
                            result.success(destPath);
                        }

                        @Override
                        public void onFail() {
                            result.error("error", null, null);
                        }

                        @Override
                        public void onProgress(float percent) {
                        }
                    });
                }

            }
        });
    }

    private Locale getLocale() {
        Configuration config = getResources().getConfiguration();
        Locale sysLocale = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            sysLocale = getSystemLocale(config);
        } else {
            sysLocale = getSystemLocaleLegacy(config);
        }

        return sysLocale;
    }

    @SuppressWarnings("deprecation")
    public static Locale getSystemLocaleLegacy(Configuration config) {
        return config.locale;
    }

    @TargetApi(Build.VERSION_CODES.N)
    public static Locale getSystemLocale(Configuration config) {
        return config.getLocales().get(0);
    }

}