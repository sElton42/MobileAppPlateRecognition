package com.example.reconhecimentodeplacaspython;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.FileProvider;

import com.chaquo.python.PyObject;
import com.chaquo.python.Python;
import com.chaquo.python.android.AndroidPlatform;
import com.example.reconhecimentodeplacaspython.ml.BestFp16Yolov5mSeg;
import com.example.reconhecimentodeplacaspython.ml.BestFp16Yolov5nPlaca;
import com.example.reconhecimentodeplacaspython.ml.ModelLetraRec;
import com.example.reconhecimentodeplacaspython.ml.ModelNumsRec;

import org.tensorflow.lite.DataType;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.List;

public class MainActivity extends AppCompatActivity {
    
    private String currentPhotoPath;
    Button camera, gallery;
    ImageView imageView, imageView2;
    TextView result;
    TextView situacaoPlaca;
    TextView initialText;
    OutputStream outputStream;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        camera = findViewById(R.id.buttonCamera);
        gallery = findViewById(R.id.buttonGallery);
        initialText = findViewById(R.id.textView1);
        result = findViewById(R.id.textViewResult);
        situacaoPlaca = findViewById(R.id.textViewSituacao);
        imageView = findViewById(R.id.imageView);
        imageView2 = findViewById(R.id.imageView2);

        if (! Python.isStarted()) {
            Python.start(new AndroidPlatform(getApplicationContext()));
        }

        // FUNÇÕES PARA ACIONAR A CÂMERA OU A GALERIA PARA PODER PEGAR A IMAGEM
        camera.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(checkSelfPermission(android.Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED){
                    String filename = "photo";
                    File storageDirectory = getExternalFilesDir(Environment.DIRECTORY_PICTURES);
                    try {
                        File imageFile = File.createTempFile(filename, ".png", storageDirectory);
                        currentPhotoPath = imageFile.getAbsolutePath();
                        Uri imageUri = FileProvider.getUriForFile(MainActivity.this, "com.example.reconhecimentodeplacaspython.fileprovider", imageFile);
                        Intent cameraIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                        cameraIntent.putExtra(MediaStore.EXTRA_OUTPUT, imageUri);
                        startActivityForResult(cameraIntent, 3);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }else{
                    requestPermissions(new String[]{Manifest.permission.CAMERA}, 100);
                }
            }
        });

        gallery.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent cameraIntent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
                startActivityForResult(cameraIntent, 1);
            }
        });
    }

    public void runYoloPlacas(Bitmap image) {

        initialText.setText("Imagem Obtida:");
        Long tempo_placas = System.currentTimeMillis();

        try {
            BestFp16Yolov5nPlaca model = BestFp16Yolov5nPlaca.newInstance(getApplicationContext());
            TensorBuffer inputFeature0 = TensorBuffer.createFixedSize(new int[]{1, 1088, 1088, 3}, DataType.FLOAT32);
            ByteBuffer byteBuffer = ByteBuffer.allocateDirect(4 * 1088 * 1088 * 3);
            byteBuffer.order(ByteOrder.nativeOrder());
            int[] intValues = new int[1088 * 1088];
            image.getPixels(intValues, 0, image.getWidth(), 0, 0, image.getWidth(), image.getHeight());
            int pixel = 0;
            Log.d("SAIDA_APP", "---------------- INICIANDO BUFFERIZAÇÃO DA IMAGEM----------------");
            for(int i = 0; i < 1088; i++){
                for(int j = 0; j < 1088; j++){
                    int val = intValues[pixel++];
                    byteBuffer.putFloat(((val >> 16) & 0xFF) * (1.f / 255));
                    byteBuffer.putFloat(((val >> 8) & 0xFF) * (1.f / 255));
                    byteBuffer.putFloat((val & 0xFF) * (1.f / 255));
                }
            }

            inputFeature0.loadBuffer(byteBuffer);
            BestFp16Yolov5nPlaca.Outputs outputs = model.process(inputFeature0);
            TensorBuffer outputFeature0 = outputs.getOutputFeature0AsTensorBuffer();
            // PEGA SAÍDA DO MODELO NA FORMA DE UM VETOR
            float[] saidaBuffer = outputFeature0.getFloatArray();
            tempo_placas = ( System.currentTimeMillis() - tempo_placas);
            Log.d("SAIDA_APP_TEMPO_DECORRIDO_PLACAS", ""+tempo_placas);

            // PEGA DETECÇÃO COM A MAIOR CONFIANÇA
            float[] confidencesPlate = new float[saidaBuffer.length];
            int aux = 0;
            for(int i = 0; i < saidaBuffer.length; i++) {
                if(i<5) {
                    confidencesPlate[i] = saidaBuffer[i];
                    if(aux == 4) {
                        aux = 0;
                    } else {
                        aux = aux + 1;
                        confidencesPlate[i] = 0;
                    }
                } else {
                    confidencesPlate[i] = saidaBuffer[i];
                    if(aux == 5) {
                        aux = 0;
                    } else {
                        aux = aux + 1;
                        confidencesPlate[i] = 0;
                    }
                }
            }
            int maxPosConf = getMax(confidencesPlate);

            // PEGA AS POSIÇÕES DA DETECÇÃO
            int xCenter = Math.round(1088*saidaBuffer[maxPosConf-4]);
            int yCenter = Math.round(1088*saidaBuffer[maxPosConf-3]);
            int width = Math.round(1088*saidaBuffer[maxPosConf-2]);
            int height = Math.round(1088*saidaBuffer[maxPosConf-1]);
            float confidences = saidaBuffer[maxPosConf];
            int xi = xCenter - Math.round(width/2);
            int xf = xCenter + Math.round(width/2);
            int yi = yCenter - Math.round(height/2);
            int yf = yCenter + Math.round(height/2);

            Log.d("SAIDA_APP", "POSIÇÃO DA PLACA: yi: "+yi+" yf: "+yf+" xi: "+xi+" xf: "+xf+" confidences: "+confidences);

            // RECORTA A PLACA
            Bitmap placaCrop = Bitmap.createBitmap(image, xi, yi, width, height);
            // REDIMENSIONA A PLACA RECORTADA PARA 240X80
            Bitmap imagePlacaCrop = Bitmap.createScaledBitmap(placaCrop, 240, 80, false);
            Bitmap imagePlacaPad = Bitmap.createBitmap(256, 256, imagePlacaCrop.getConfig());

            // GERA A IMAGEM DA PLACA 256X256
            Canvas canvas = new Canvas(imagePlacaPad);
            canvas.drawColor(Color.BLACK);
            canvas.drawBitmap(imagePlacaCrop, 0, 0, null);

            // DESENHA UM RETÂNGULO NO OBJETO DETECTADO NA IMAGEM ORIGINAL COM PADDING
            Canvas canvasImgOrig = new Canvas(image);
            Paint paint = new Paint();
            paint.setColor(Color.RED);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(5);
            canvasImgOrig.drawRect(xi,yi,xf,yf, paint);

            // REMOVE PADDING E PLOTA IMAGEM ORIGINAL COM RETÂNGULO DESENHADO
            Bitmap imgOrNoPad = Bitmap.createBitmap(image, 0,0, 1080, 1080);
            imageView.setImageBitmap(imgOrNoPad);

            imageView2.setImageBitmap(imagePlacaCrop);
            runYoloSegmentacao(imagePlacaPad, imgOrNoPad);
            model.close();
        } catch (IOException e) {

        }
    }
    public String runYoloSegmentacao(Bitmap image, Bitmap OrigImage) {
        Long tempo_segmentacao = System.currentTimeMillis();
        try {
            BestFp16Yolov5mSeg model = BestFp16Yolov5mSeg.newInstance(getApplicationContext());
            TensorBuffer inputFeature0 = TensorBuffer.createFixedSize(new int[]{1, 256, 256, 3}, DataType.FLOAT32);

            ByteBuffer byteBuffer = ByteBuffer.allocateDirect(4 * 256 * 256 * 3);
            byteBuffer.order(ByteOrder.nativeOrder());
            int[] intValues = new int[256 * 256];
            image.getPixels(intValues, 0, image.getWidth(), 0, 0, image.getWidth(), image.getHeight());
            int pixel = 0;
            for(int i = 0; i < 256; i++){
                for(int j = 0; j < 256; j++){
                    int val = intValues[pixel++];
                    byteBuffer.putFloat(((val >> 16) & 0xFF) * (1.f / 255));
                    byteBuffer.putFloat(((val >> 8) & 0xFF) * (1.f / 255));
                    byteBuffer.putFloat((val & 0xFF) * (1.f / 255));
                }
            }

            inputFeature0.loadBuffer(byteBuffer);

            BestFp16Yolov5mSeg.Outputs outputs = model.process(inputFeature0);
            TensorBuffer outputFeature0 = outputs.getOutputFeature0AsTensorBuffer();

            float[] saidaBuffer = outputFeature0.getFloatArray();

            tempo_segmentacao = ( System.currentTimeMillis() - tempo_segmentacao);
            Log.d("SAIDA_APP_TEMPO_DECORRIDO_SEGMENTACAO", ""+tempo_segmentacao);

            Python py = Python.getInstance();
            final PyObject pyobj = py.getModule("script");
            PyObject obj = pyobj.callAttr("main", saidaBuffer); // PEGA A SAÍDA DO SCRIPT

            List<PyObject> caracteres = obj.asList();
            String placa_resultado = "";
            Long tempo_caracteres_total = System.currentTimeMillis();
            for(int i = 0; i < caracteres.size(); i++) {
                PyObject charObj = caracteres.get(i);
                int bxi = charObj.asList().get(0).toInt();
                int bxf = charObj.asList().get(1).toInt();
                int byi = charObj.asList().get(2).toInt();
                int byf = charObj.asList().get(3).toInt();

                if(i == 7) {
                    break;
                }

                Log.d("SAIDA_APP", "Char "+i+" Pos: xi = " +bxi+ " xf = " +bxf+ " yi = " +byi+ " yf = " + byf);

                // DESENHA UM RETÂNGULO VERMELHO AO REDOR DOS CARACTERES
                Canvas canvasImgOrig = new Canvas(image);
                Paint paint = new Paint();
                paint.setColor(Color.RED);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(1);
                Rect rect = new Rect(bxi, byi, bxf, byf);
                canvasImgOrig.drawRect(rect, paint);

                if(i < 3) {
                    Bitmap charCrop = Bitmap.createBitmap(image, bxi, byi, bxf-bxi, byf-byi);
                    Bitmap charCropPad = redimenImage(charCrop);
                    charCropPad  = Bitmap.createScaledBitmap(charCropPad, 20, 30, false);
                    char letra = runCnnLetras(charCropPad);
                    placa_resultado = placa_resultado + letra;
                } else {
                    Bitmap charCrop = Bitmap.createBitmap(image, bxi, byi, bxf-bxi, byf-byi);
                    Bitmap charCropPad = redimenImage(charCrop);
                    charCropPad = Bitmap.createScaledBitmap(charCropPad, 20, 30, false);
                    char numel = runCnnNums(charCropPad);
                    placa_resultado = placa_resultado + numel;
                }

                // RECORTA IMAGEM DA PLACA
                Bitmap placaSegmentada = Bitmap.createBitmap(image, 0, 0, 240, 80);
                imageView2.setImageBitmap(placaSegmentada);
            }

            tempo_caracteres_total = ( System.currentTimeMillis() - tempo_caracteres_total);
            Log.d("SAIDA_APP_TEMPO_DECORRIDO_CARACTERES", ""+tempo_caracteres_total);

            Log.d("SAIDA_APP", ""+placa_resultado);
            result.setText("Placa Identificada: "+ placa_resultado);
            model.close();

//          IMPLEMENTAÇÃO DA BIBLIOTECA RETROFIT PARA OBTER A SITUAÇÃO DA PLACA VEICULAR
//            String textoPlaca = placa_resultado;
//            Methods methods = RetrofitClient.getRetrofitInstance().create(Methods.class);
//            Call<PlacaModel> call = methods.buscarSituacao(placa_resultado);
//            call.enqueue(new Callback<PlacaModel>() {
//                @Override
//                public void onResponse(Call<PlacaModel> call, Response<PlacaModel> response) {
//                    PlacaModel placa = response.body();
//                    Log.d("PLACA_RES", ""+placa);
//                    situacaoPlaca.setText(placa.getSituacao());
//                    String situacaoPlacaAPI = situacaoPlaca.getText().toString();
//                    saveImage(OrigImage, textoPlaca, situacaoPlacaAPI);
//                }
//
//                @Override
//                public void onFailure(Call<PlacaModel> call, Throwable t) {
//                    Log.e("PLACA_RES", "Erro ao buscar o situacao do veiculo" + t.getMessage());
//                }
//            });

            return placa_resultado;

        } catch (IOException e) {

        }
        return "";
    }

    public char runCnnLetras(Bitmap image){
        Long tempo_cnnletras = System.currentTimeMillis();
        try {
            ModelLetraRec model = ModelLetraRec.newInstance(getApplicationContext());
            TensorBuffer inputFeature0 = TensorBuffer.createFixedSize(new int[]{1, 30, 20, 3}, DataType.FLOAT32);

            ByteBuffer byteBuffer = ByteBuffer.allocateDirect(4 * 30 * 20 * 3);
            byteBuffer.order(ByteOrder.nativeOrder());
            int[] intValues = new int[30*20];
            image.getPixels(intValues, 0, image.getWidth(), 0, 0, image.getWidth(), image.getHeight());
            int pixel = 0;
            for(int i = 0; i < 30; i++){
                for(int j = 0; j < 20; j++){
                    int val = intValues[pixel++];
                    byteBuffer.putFloat(((val >> 16) & 0xFF) * (1.f / 255));
                    byteBuffer.putFloat(((val >> 8) & 0xFF) * (1.f / 255));
                    byteBuffer.putFloat((val & 0xFF) * (1.f / 255));
                }
            }

            inputFeature0.loadBuffer(byteBuffer);

            ModelLetraRec.Outputs outputs = model.process(inputFeature0);
            TensorBuffer outputFeature0 = outputs.getOutputFeature0AsTensorBuffer();

            int maxPos = getMax(outputFeature0.getFloatArray());
            char[] classes = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
                    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S',
                    'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};

            char charactere = classes[maxPos];
            model.close();

            tempo_cnnletras = ( System.currentTimeMillis() - tempo_cnnletras);
            Log.d("SAIDA_APP_TEMPO_DECORRIDO_LETRAS", ""+tempo_cnnletras);

            return charactere;

        } catch (IOException e) {
            Log.d("RUNCNNLETRAS", "----------------NÃO FOI POSSÍVEL RODAR O MODELO----------------");
        }
        char charactereFail = '@';
        return charactereFail;
    }

    public char runCnnNums(Bitmap image) {
        Long tempo_cnnnums = System.currentTimeMillis();
        try {
            ModelNumsRec model = ModelNumsRec.newInstance(getApplicationContext());
            TensorBuffer inputFeature0 = TensorBuffer.createFixedSize(new int[]{1, 30, 20, 3}, DataType.FLOAT32);

            ByteBuffer byteBuffer = ByteBuffer.allocateDirect(4 * 30 * 20 * 3);
            byteBuffer.order(ByteOrder.nativeOrder());
            int[] intValues = new int[30*20];
            image.getPixels(intValues, 0, image.getWidth(), 0, 0, image.getWidth(), image.getHeight());
            int pixel = 0;
            for(int i = 0; i < 30; i++){
                for(int j = 0; j < 20; j++){
                    int val = intValues[pixel++];
                    byteBuffer.putFloat(((val >> 16) & 0xFF) * (1.f / 255));
                    byteBuffer.putFloat(((val >> 8) & 0xFF) * (1.f / 255));
                    byteBuffer.putFloat((val & 0xFF) * (1.f / 255));
                }
            }

            inputFeature0.loadBuffer(byteBuffer);
            ModelNumsRec.Outputs outputs = model.process(inputFeature0);
            TensorBuffer outputFeature0 = outputs.getOutputFeature0AsTensorBuffer();
            int maxPos = getMax(outputFeature0.getFloatArray());
            maxPos = maxPos + 48;
            char numel = (char) (maxPos);
            model.close();
            tempo_cnnnums = ( System.currentTimeMillis() - tempo_cnnnums);
            Log.d("SAIDA_APP_TEMPO_DECORRIDO_NUMS", ""+tempo_cnnnums);
            return numel;

        } catch (IOException e) {
            Log.d("RUNCNNNUMS", "----------------NÃO FOI POSSÍVEL RODAR O MODELO----------------");
        }
        char numelFail = '@';
        return numelFail;
    }

    // FUNÇÃO ACIONADA APOS CLICAR EM PEGAR IMAGEM DA GALERIA OU DA CAMERA
    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if(resultCode == RESULT_OK){
            // PEGA A IMAGEM DA CÂMERA
            if(requestCode == 3){
                Bitmap image = BitmapFactory.decodeFile(currentPhotoPath);

                image = Bitmap.createScaledBitmap(image, 1088, 1088, false);
                image = rotateBitmap(image);
                imageView.setImageBitmap(image);
                runYoloPlacas(image);
            // PEGA A IMAGEM DA GALERIA
            }else{
                Uri dat = data.getData();
                Bitmap image = null;
                try {
                    image = MediaStore.Images.Media.getBitmap(this.getContentResolver(), dat);
                } catch (IOException e) {
                    e.printStackTrace();
                }

                Bitmap imgBitmap = Bitmap.createBitmap(1088, 1088, image.getConfig());

                Canvas canvas = new Canvas(imgBitmap);
                canvas.drawColor(Color.BLACK);
                canvas.drawBitmap(image, 0, 0, null);

                Long tempo = System.currentTimeMillis();
                runYoloPlacas(imgBitmap);
                tempo = ( System.currentTimeMillis() - tempo);
                Log.d("SAIDA_APP_TEMPO_DECORRIDO_TOTAL", ""+tempo);
            }
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    // ROTACIONA IMAGEM EM 90°
    public Bitmap rotateBitmap(Bitmap bitmap){
        android.graphics.Matrix matrix = new android.graphics.Matrix();
        matrix.postScale((float)1, (float)1 );
        matrix.postRotate(90);
        Bitmap bitmap2 = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
        return bitmap2;
    }

    int getMax(float[] arr){
        int max=0;
        for(int i=0; i<arr.length; i++){
            if(arr[i] > arr[max]) max=i;
        }
        return max;
    }

    // ALTERADO P/ SALVAR COM HORA + CHARS DA PLACA.
    // USADO SOMENTE COM A BIBLIOTECA RETROFIT
//    private void saveImage(Bitmap image, String charsPlaca, String situacaoPlaca) {
//        File dir = new File(Environment.getExternalStorageDirectory(), "Pictures");
//        if(!dir.exists()) {
//            dir.mkdir();
//        }
//        SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy-HH-mm-ss");
//        String currentDateAndTime = sdf.format(new Date());
//        String regularidade;
//
////        File file = new File(dir, System.currentTimeMillis()+"_"+charsPlaca+"_"+".jpg");
//
//        if(situacaoPlaca.equals("Sem restrição")){
//            regularidade = "regular";
//        } else {
//            regularidade = "irregular";
//        }
//
//        File file = new File(dir, currentDateAndTime+"_"+charsPlaca+"_"+regularidade+".jpg");
//
//        try {
//            outputStream = new FileOutputStream(file);
//        } catch (FileNotFoundException e) {
//            e.printStackTrace();
//        }
//        image.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
//        Log.d("SALVARIMAGEM", "IMAGEM FOI SALVA COM SUCESSO");
//        try {
//            outputStream.flush();
//        } catch (IOException e) {
//            e.printStackTrace();
//        }
//        try {
//            outputStream.close();
//        } catch (IOException e) {
//            e.printStackTrace();
//        }
//    }

    public Bitmap redimenImage(Bitmap image) {
        int old_image_height = image.getHeight();
        int old_image_width = image.getWidth();

        int new_image_width;
        int new_image_height;
        if(old_image_height > old_image_width){
            new_image_width = old_image_height;
            new_image_height = old_image_height;
        } else {
            new_image_width = old_image_width;
            new_image_height = old_image_width;
        }

        Bitmap charPadding = Bitmap.createBitmap(new_image_width, new_image_height, image.getConfig());
        int xCenter = (new_image_width - old_image_width) / 2;
        int yCenter = (new_image_height - old_image_height) / 2;

        Canvas canvas = new Canvas(charPadding);
        canvas.drawColor(Color.BLACK);
        canvas.drawBitmap(image, xCenter, yCenter, null);

        return charPadding;
    }
}