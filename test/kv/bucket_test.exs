defmodule KV.BucketTest do
    # A cláusula "use" permite ao módulo ExUnit.Case inserir códigos e funcionalidades neste módulo. Isso é desejado, já que queremos que este módulo seja usado nas rotinas de testes, então ele precisa ser usado pelo módulo ExUnit.Case.
    # Foi passado como argumento async: true, o que significa que os testes definidos aqui rodarão em paralelo com outras rotinas de testes. Isso é muito útil quando há várias rotinas de testes a serem executadas.
    # OBS: Caso um teste dependa de outro para acontecer, ou de alguma operação, como leitura/escrita em banco de dados, não se deve usar o argumento async.
    use ExUnit.Case, async: true

    # Essa macro é uma callback que é chamada antes de cada um dos testes definidos neste módulo. Ela basicamente cria um bucket e o retorna dentro de um mapa.
    # Esse mapa é passado como argumento para os testes, que podem acessá-lo a partir do mecanismo de "pattern matching".
    setup do
        bucket = start_supervised!(KV.Bucket)
        %{bucket: bucket}
    end

    test "stores values by key", %{bucket: bucket} do
        assert KV.Bucket.get(bucket, "milk") == nil

        KV.Bucket.put(bucket, "milk", 3)
        assert KV.Bucket.get(bucket, "milk") == 3
    end

    test "deletes a value by key", %{bucket: bucket} do
        KV.Bucket.delete(bucket, "milk")
        assert KV.Bucket.get(bucket, "milk") == nil
    end

    test "are temporary workers" do
        assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary
    end
end