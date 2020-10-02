package com.subitolabs.cordova.galleryapi;


import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.media.ThumbnailUtils;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.util.Size;
import android.widget.Toast;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

public class GalleryAPI extends CordovaPlugin {
    public static final String ACTION_CHECK_PERMISSION = "checkPermission";
    public static final String ACTION_GET_MEDIA = "getMedia";
    public static final String ACTION_GET_MEDIA_THUMBNAIL = "getMediaThumbnail";
    public static final String ACTION_GET_HQ_IMAGE_DATA = "getHQImageData";
    public static final String ACTION_GET_ALBUMS = "getAlbums";
    public static final String ACTION_GET_CLEAR_HQ_STORAGE = "clearHQStorage";
    public static final String DIR_NAME = "files";
    public static final String SUB_DIR_NAME = "mendr_hq";

    private static final int BASE_SIZE = 300;

    private static BitmapFactory.Options ops = null;

    private static final int STORAGE_PERMISSIONS_REQUEST = 1;

    private CallbackContext cbc = null;

    @Override
    public boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        try {
            if (ACTION_GET_MEDIA.equals(action)) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                            JSONObject object = (JSONObject) args.get(0);
                            ArrayOfObjects albums = getMedia(object.getString("title"));
                            callbackContext.success(new JSONArray(albums));
                        } catch (Exception e) {
                            e.printStackTrace();
                            callbackContext.error(e.getMessage());
                        }
                    }
                });

                return true;
            } else if (ACTION_CHECK_PERMISSION.equals(action)) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        cbc = callbackContext;
                        checkPermission();
                    }
                });
                return true;
            } else if (ACTION_GET_MEDIA_THUMBNAIL.equals(action)) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                            JSONObject media = getMediaThumbnail((JSONObject) args.get(0));
                            callbackContext.success(media);
                        } catch (Exception e) {
                            e.printStackTrace();
                            callbackContext.error(e.getMessage());
                        }
                    }
                });
                return true;
            } else if (ACTION_GET_HQ_IMAGE_DATA.equals(action)) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                            JSONObject media = getHQImageData((JSONObject) args.get(0));
                            callbackContext.success(media);
                        } catch (Exception e) {
                            e.printStackTrace();
                            callbackContext.error(e.getMessage());
                        }
                    }
                });
                return true;
            } else if (ACTION_GET_ALBUMS.equals(action)) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                            ArrayOfObjects albums = getBuckets();
                            callbackContext.success(new JSONArray(albums));
                        } catch (Exception e) {
                            e.printStackTrace();
                            callbackContext.error(e.getMessage());
                        }
                    }
                });

                return true;

            } else if (ACTION_GET_CLEAR_HQ_STORAGE.equals(action)) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                            String response = clearHQStorage();
                            callbackContext.success(new String(response));
                        } catch (Exception e) {
                            e.printStackTrace();
                            callbackContext.error(e.getMessage());
                        }
                    }
                });

                return true;
            }
            callbackContext.error("Invalid action");
            return false;
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
            return false;
        }
    }

    public ArrayOfObjects getBuckets() throws JSONException {

        Object columns = new Object() {{
            put("id", MediaStore.Images.ImageColumns.BUCKET_ID);
            put("title", MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME);
            put("data", MediaStore.Images.ImageColumns.DATA);
            put("duration", MediaStore.MediaColumns.DURATION);
            put("int.height", MediaStore.Images.ImageColumns.HEIGHT);
            put("int.width", MediaStore.Images.ImageColumns.WIDTH);
            put("int.orientation", MediaStore.Images.ImageColumns.ORIENTATION);
        }};

        final ArrayOfObjects results = queryContentProvider(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, "");
        // GROUP BY no longer supported, apparently

        System.out.println("Album" + results);

        Object collection = null;
        for (int i = 0; i < results.size(); i++) {
            collection = results.get(i);
            if (collection.getString("title").equals("Camera")) {
                results.remove(i);
                break;
            }
        }

        if (collection != null)
            results.add(0, collection);

        return results;
    }

    private ArrayOfObjects getMedia(String bucket) throws JSONException {

        Object columns = new Object() {{
            put("int.id", MediaStore.Images.Media._ID);
            put("data", MediaStore.MediaColumns.DATA);
            //put("asdf", MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
            //put("externalurl", MediaStore.Images.Media.getContentUri(MediaStore.Images.ImageColumns.VOLUME_NAME));
            put("int.created", MediaStore.Images.ImageColumns.DATE_ADDED);
            put("title", MediaStore.Images.ImageColumns.DISPLAY_NAME);
            put("filename", MediaStore.Images.ImageColumns.DISPLAY_NAME);
            put("int.height", MediaStore.Images.ImageColumns.HEIGHT);
            put("int.width", MediaStore.Images.ImageColumns.WIDTH);
            put("int.orientation", MediaStore.Images.ImageColumns.ORIENTATION);
            put("duration", MediaStore.MediaColumns.DURATION);
            put("mime_type", MediaStore.Images.ImageColumns.MIME_TYPE);
            put("float.lat", MediaStore.Images.ImageColumns.LATITUDE);
            put("float.lon", MediaStore.Images.ImageColumns.LONGITUDE);
            put("int.size", MediaStore.Images.ImageColumns.SIZE);
            put("int.thumbnail_id", MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC);
        }};

        final ArrayOfObjects results = queryContentProvider(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, "bucket_display_name = '" + bucket + "'");
        final ArrayOfObjects resultsVideo = queryContentProvider(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, columns, "bucket_display_name = '" + bucket + "'");

        ArrayOfObjects temp = new ArrayOfObjects();
        //Uri uriExternal = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

        for (Object media : results) {

            System.out.println("Image Object" + media);

            //media.put("data", Uri.withAppendedPath(uriExternal, "" + media.getLong("id")));
            media.put("hqpath", "");
            media.put("thumbs", "");
            media.put("thumbnail", "");
            media.put("error", "false");
            media.put("isVideo", false);

            if (media.getInt("height") <= 0 || media.getInt("width") <= 0) {
                System.err.println(media);
            } else {
                temp.add(media);
            }
        }

        for (Object media : resultsVideo) {

            //System.out.println("Video Object" + media);


            //media.put("data", Uri.withAppendedPath(uriExternal, "" + media.getLong("id")));
            media.put("thumbnail", "");
            media.put("error", "false");
            media.put("isVideo", true);

            if (media.getInt("height") <= 0 || media.getInt("width") <= 0) {
                System.err.println(media);
            } else {
                System.out.println("ADDING VIDEO!");
                temp.add(media);
            }
        }

        Collections.reverse(temp);
        return temp;
    }

    private void checkPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            List<String> permissions = new ArrayList<String>();

            boolean isReadDenied = false;
            boolean isWriteDenied = false;

            if (ContextCompat.checkSelfPermission(this.getContext(), Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(this.cordova.getActivity(), Manifest.permission.READ_EXTERNAL_STORAGE))
                    isReadDenied = true;
                else
                    permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE);
            }

            if (ContextCompat.checkSelfPermission(this.getContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(this.cordova.getActivity(), Manifest.permission.WRITE_EXTERNAL_STORAGE))
                    isWriteDenied = true;
                else
                    permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
            }

            if (isReadDenied || isWriteDenied) {
                String message;

                if (isReadDenied && isWriteDenied)
                    message = "Read and Write permissions are denied";
                else if (isReadDenied)
                    message = "Read permission is denied";
                else
                    message = "Write permission is denied";

                sendCheckPermissionResult(false, message);
            } else if (permissions.size() > 0) {
                String[] pArray = new String[permissions.size()];
                pArray = permissions.toArray(pArray);
                ActivityCompat.requestPermissions(this.cordova.getActivity(), pArray, STORAGE_PERMISSIONS_REQUEST);
            } else
                sendCheckPermissionResult(true, "Authorized");
        } else
            sendCheckPermissionResult(true, "Authorized");
    }

    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
        switch (requestCode) {
            case STORAGE_PERMISSIONS_REQUEST: {
                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED)
                    sendCheckPermissionResult(true, "Authorized");
                else
                    sendCheckPermissionResult(false, "Denied");
                return;
            }
        }
    }

    private void sendCheckPermissionResult(Boolean success, String message) {
        try {
            JSONObject result = new JSONObject();
            result.put("success", success);
            result.put("message", message);
            cbc.success(result);
        } catch (Exception e) {
            e.printStackTrace();
            cbc.error(e.getMessage());
        }
    }

    private JSONObject getMediaThumbnail(JSONObject media) throws JSONException {

        File thumbnailPath = thumbnailPathFromMediaId(media.getString("id"));
        if (thumbnailPath.exists()) {
            System.out.println("Thumbnail Already Exists!!!. Not Creating New One");
            media.put("thumbnail", thumbnailPath);
        } else {
            if (ops == null) {
                ops = new BitmapFactory.Options();
                ops.inJustDecodeBounds = false;
                ops.inSampleSize = 1;
            }
            media.put("error", "true");

            File image = new File(media.getString("data"));
            Boolean isVideo = media.getBoolean("isVideo");
            //System.out.println("Is Video? " + isVideo);

            int sourceWidth = media.getInt("width");
            int sourceHeight = media.getInt("height");

            if (sourceHeight > 0 && sourceWidth > 0) {
                int destinationWidth, destinationHeight;

                if (sourceWidth > sourceHeight) {
                    destinationHeight = BASE_SIZE;
                    destinationWidth = (int) Math.ceil(destinationHeight * ((double) sourceWidth / sourceHeight));
                } else {
                    destinationWidth = BASE_SIZE;
                    destinationHeight = (int) Math.ceil(destinationWidth * ((double) sourceHeight / sourceWidth));
                }

                Bitmap originalImageBitmap;

                if(isVideo){
                    //Size thumbSize = new Size(400, 400);
                    originalImageBitmap = ThumbnailUtils.createVideoThumbnail(image.getAbsolutePath(), 1);
                }else{
                    if (sourceWidth * sourceHeight > 600000 && sourceWidth * sourceHeight < 1000000) {
                        ops.inSampleSize = 1;
                    } else if (sourceWidth * sourceHeight > 1000000) {
                        ops.inSampleSize = 4;
                    }
                    originalImageBitmap = BitmapFactory.decodeFile(image.getAbsolutePath(), ops); //creating bitmap of original image
                }

                if (originalImageBitmap == null) {
                    ops.inSampleSize = 1;
                    originalImageBitmap = BitmapFactory.decodeFile(image.getAbsolutePath(), ops);
                }

                if (originalImageBitmap != null) {

                    if (destinationHeight <= 0 || destinationWidth <= 0) {
                        System.out.println("destinationHeight: " + destinationHeight + "  destinationWidth: " + destinationWidth);
                    }

                    Bitmap thumbnailBitmap = Bitmap.createScaledBitmap(originalImageBitmap, destinationWidth, destinationHeight, true);
                    originalImageBitmap.recycle();

                    if (thumbnailBitmap != null) {
                        int orientation = media.getInt("orientation");
                        if (orientation > 0)
                            thumbnailBitmap = rotate(thumbnailBitmap, orientation);

                        byte[] thumbnailData = getBytesFromBitmap(thumbnailBitmap);
                        thumbnailBitmap.recycle();
                        if (thumbnailData != null) {
                            FileOutputStream outStream;
                            try {
                                outStream = new FileOutputStream(thumbnailPath);
                                outStream.write(thumbnailData);
                                outStream.close();
                            } catch (IOException e) {
                                Log.e("Mendr", "Couldn't write the thumbnail image data");
                                e.printStackTrace();
                            }

                            if (thumbnailPath.exists()) {
                                System.out.println("Thumbnail didn't Exists!!!. Created New One");
                                media.put("thumbnail", thumbnailPath);
                                media.put("error", "false");
                            }
                        } else
                            Log.e("Mendr", "Couldn't convert thumbnail bitmap to byte array");
                    } else
                        Log.e("Mendr", "Couldn't create the thumbnail bitmap");
                } else
                    Log.e("Mendr", "Couldn't decode the original image");
            } else
                Log.e("Mendr", "Invalid Media!!! Image width or height is 0");
        }

        return media;
    }

    private JSONObject getHQImageData(JSONObject media) throws JSONException {

        File imagePath = imagePathFromMediaId(media.getString("savefilename"));
        Boolean isVideo = media.getBoolean("isVideo");
        System.out.println("isVideo: " + isVideo + "  media: " + media);
        media.put("hqpath", imagePath.toString());
        System.out.println("MEDIA PATH: " + imagePath.toString());

        if(isVideo){

            String destPath = videoPathFromMediaId(media.getString("savefilename"));
            media.put("hqpath", imagePath.toString());

            try {
                FileOutputStream newFile = new FileOutputStream (destPath, false);
                FileInputStream oldFile = new FileInputStream (media.getString("data"));

                // Transfer bytes from in to out
                byte[] buf = new byte[1024];
                int len;
                while ((len = oldFile.read(buf)) > 0) {
                    newFile.write(buf, 0, len);
                }
                newFile.close();
                oldFile.close();
                System.out.println("FileSaved?:");

                // create video thumbnails
                //ArrayOfObjects thumbs;




            } catch (IOException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }

        }else{

            BitmapFactory.Options ops = new BitmapFactory.Options();
            ops.inJustDecodeBounds = false;
            ops.inSampleSize = 1;

            File image = new File(media.getString("data"));

            int sourceWidth = media.getInt("width");
            int sourceHeight = media.getInt("height");

            if (sourceHeight > 0 && sourceWidth > 0) {
                Bitmap originalImageBitmap = BitmapFactory.decodeFile(image.getAbsolutePath(), ops); //creating bitmap of original image

                if (originalImageBitmap != null) {
                    int orientation = media.getInt("orientation");
                    if (orientation > 0)
                        originalImageBitmap = rotate(originalImageBitmap, orientation);

                    byte[] imageData = getBytesFromBitmap(originalImageBitmap);
                    originalImageBitmap.recycle();
                    if (imageData != null) {
                        FileOutputStream outStream;
                        try {
                            outStream = new FileOutputStream(imagePath);
                            outStream.write(imageData);
                            outStream.close();

                        } catch (IOException e) {
                            Log.e("Mendr", "Couldn't write the image data");
                            e.printStackTrace();
                        }
                    }
                } else
                    Log.e("Mendr", "Couldn't decode the original image");
            } else
                Log.e("Mendr", "Invalid Media!!! Image width or height is 0");
        }

        return media;

    }

    private String clearHQStorage() throws JSONException {

        String response = null;

        // Removing any existing files
        File rootDir = new File(this.getContext().getApplicationInfo().dataDir, DIR_NAME);
        File dir = new File(rootDir, SUB_DIR_NAME);

        //check if root directory exist
        if (rootDir.exists()) {
            //root directory exists
            if (dir.exists()) {
                //dir exists so deleting it
                deleteRecursive(dir);
                response = "Directory deleted.";
            }else{
                response = "Directory does not exist.";
            }
        }else{
            response = "Directory does not exist.";
        }

        return response;

    }

    private byte[] getBytesFromBitmap(Bitmap bitmap) {
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
        return stream.toByteArray();
    }

    private static Bitmap rotate(Bitmap source, int orientation) {
        Matrix matrix = new Matrix();
        matrix.postRotate((float) orientation);
        return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, false);
    }

    private File thumbnailPathFromMediaId(String mediaId) {
        File thumbnailPath = null;

        String thumbnailName = mediaId + "_mthumb.png";
        File dir = new File(this.getContext().getApplicationInfo().dataDir, DIR_NAME);
        if (!dir.exists()) {
            if (!dir.mkdirs()) {
                Log.e("Mendr", "Failed to create storage directory.");
                return thumbnailPath;
            }
        }

        thumbnailPath = new File(dir.getPath() + File.separator + thumbnailName);

        return thumbnailPath;
    }

    private File imagePathFromMediaId(String mediaFileName) {
        File imagePath = null;

        File rootDir = new File(this.getContext().getApplicationInfo().dataDir, DIR_NAME);
        File dir = new File(rootDir, SUB_DIR_NAME);

        //check if root directory exist
        if (rootDir.exists()) {
            //root directory exists
            if (dir.exists()) {
                //dir exists so deleting it
                //deleteRecursive(dir);
            }else{
                if (!dir.mkdirs()) {
                    Log.e("Mendr", "Failed to create hq storage directory.");
                    return imagePath;
                } else {
                    //dir created successfully
                }
            }

        } else {
            //root directory doesn't exist
            //trying to create root directory
            if (!rootDir.mkdirs()) {
                Log.e("Mendr", "Failed to create root storage directory.");
                return imagePath;
            } else {
                //root dir created successfully
                if (!dir.mkdirs()) {
                    Log.e("Mendr", "Failed to create hq storage directory.");
                    return imagePath;
                } else {
                    //dir created successfully
                }
            }
        }

        //String imageName = mediaId + ".png";
        imagePath = new File(dir.getPath() + File.separator + mediaFileName);

        return imagePath;
    }

    private String videoPathFromMediaId(String mediaFileName) {
        String imagePath = null;

        File rootDir = new File(this.getContext().getApplicationInfo().dataDir, DIR_NAME);
        File dir = new File(rootDir, SUB_DIR_NAME);

        //check if root directory exist
        if (rootDir.exists()) {
            //root directory exists
            if (dir.exists()) {
                //dir exists so deleting it
                //deleteRecursive(dir);
                Log.e("Mendr", "Directory Exists!");
            }else{
                if (!dir.mkdirs()) {
                    Log.e("Mendr", "Failed to create hq storage directory.");
                    return imagePath;
                } else {
                    //dir created successfully
                }
            }

        } else {
            //root directory doesn't exist
            //trying to create root directory
            if (!rootDir.mkdirs()) {
                Log.e("Mendr", "Failed to create root storage directory.");
                return imagePath;
            } else {
                //root dir created successfully
                if (!dir.mkdirs()) {
                    Log.e("Mendr", "Failed to create SECOND hq storage directory.");
                    return imagePath;
                } else {
                    //dir created successfully
                }
            }
        }

        //String imageName = mediaId + ".png";
        imagePath = dir.getPath() + File.separator + mediaFileName;

        return imagePath;
    }

    void deleteRecursive(File fileOrDirectory) {
        if (fileOrDirectory.isDirectory())
            for (File child : fileOrDirectory.listFiles())
                deleteRecursive(child);

        fileOrDirectory.delete();
    }

    private Context getContext() {
        return this.cordova.getActivity().getApplicationContext();
    }

    private ArrayOfObjects queryContentProvider(Uri collection, Object columns, String whereClause) throws JSONException {
        final ArrayList<String> columnNames = new ArrayList<String>();
        final ArrayList<String> columnValues = new ArrayList<String>();

        Iterator<String> iteratorFields = columns.keys();

        while (iteratorFields.hasNext()) {
            String column = iteratorFields.next();

            columnNames.add(column);
            columnValues.add("" + columns.getString(column));
        }

        final Cursor cursor = getContext().getContentResolver().query(collection, columnValues.toArray(new String[columns.length()]), whereClause, null, null);
        final ArrayOfObjects buffer = new ArrayOfObjects();

        if (cursor.moveToFirst()) {
            do {
                Object item = new Object();

                for (String column : columnNames) {
                    int columnIndex = cursor.getColumnIndex(columns.get(column).toString());

                    if (column.startsWith("int.")) {
                        item.put(column.substring(4), cursor.getInt(columnIndex));
                        if (column.substring(4).equals("width") && item.getInt("width") == 0) {
                            System.err.println("cursor: " + cursor.getInt(columnIndex));

                        }
                    } else if (column.startsWith("float.")) {
                        item.put(column.substring(6), cursor.getFloat(columnIndex));
                    } else {
                        item.put(column, cursor.getString(columnIndex));
                    }
                }

                buffer.add(item);
            }
            while (cursor.moveToNext());
        }

        cursor.close();

        return buffer;
    }

    private class Object extends JSONObject {

    }

    private class ArrayOfObjects extends ArrayList<Object> {

    }
}
