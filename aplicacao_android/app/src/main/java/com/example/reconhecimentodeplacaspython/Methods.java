package com.example.reconhecimentodeplacaspython;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Path;

public interface Methods {

    @GET("{placa}/c071071d61966dbba7a33909d37bca06")
    Call<PlacaModel> buscarSituacao(@Path("placa") String placa);

}
