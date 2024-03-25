package com.example.reconhecimentodeplacaspython;

import retrofit2.Retrofit;
import retrofit2.converter.jackson.JacksonConverterFactory;

public class RetrofitClient {
    private static Retrofit retrofit;

    public static Retrofit getRetrofitInstance(){
        if(retrofit == null){
            retrofit = new Retrofit.Builder()
                    .baseUrl("https://wdapi.com.br/placas/")
                    .addConverterFactory(JacksonConverterFactory.create())
                    .build();
        }
        return retrofit;
    }

//    try {
//        Response<PlacaModel> response = call.execute();
//        PlacaModel placa = response.body();
//        Log.d("PLACA_RES", ""+placa);
//        situacaoPlaca.setText(placa.getSituacao());
//    } catch (Exception e) {
//        e.printStackTrace();
//    }

//    public RetrofitClient() {
//        this.retrofit = new Retrofit.Builder()
//                .baseUrl(BASE_URL)
//                .addConverterFactory(JacksonConverterFactory.create())
//                .build();
//    }

//    public PlacaModel getPlacaService() {
//        return this.retrofit.create(PlacaModel.class);
//    }
}
