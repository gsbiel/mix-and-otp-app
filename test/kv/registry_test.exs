defmodule KV.RegistryTest do
    @moduledoc """
        Rotina de testes para o módulo KV.Registry.
        A função start_supervised!() assegura que o GenServer vai ser desligado ao final de cada teste. Isso significa que o estado do servidor em um teste não vai influenciar nos testes subsequentes! SEMPRE USE ESSA FUNÇÃO! WEla automaticamente chama a função start_link presente no módulo que foi passado como argumento. 
    """
    use ExUnit.Case, async: true

    setup do
        registry = start_supervised!(KV.Registry)
        %{registry: registry}
    end

    test "spawns buckets", %{registry: registry} do
        assert KV.Registry.lookup(registry, "shopping") == :error

        KV.Registry.create(registry, "shopping")
        assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    end


    test "remove buckets on exit", %{registry: registry} do
        KV.Registry.create(registry, "shopping")
        {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
        Agent.stop(bucket)
        assert KV.Registry.lookup(registry, "shopping") == :error
    end

    test "remove bucket on crash", %{registry: registry} do
        KV.Registry.create(registry, "shopping")
        {:ok, bucket} = KV.Registry.lookup(registry,"shopping")

        # Interrompe o bucket de forma anormal
        # Até a versão do capítulo 4 esse teste falharia, porque o bucket está sendo interrompido por uma razão diferente de :normal. Quando isso acontece, o bucket (que é um processo do tipo Agent) vai enviar uma mensagem de exit a todos os processos com os quais está linkado. Nesse caso, cada bucket está linkado ao processo Registry, que o iniciou (através da função start_link()). Todos os processos que receberem essa mensagem vão parar também. Assim, quando um bucket falha, o Registry também falha. Por isso acontecerá um erro em KV.Registry.lookup, já que KV.Registry não vai mais existir!
        # Para evitar que o Registro pare quando um dos buckets quebra, deve-se criar um supervisor para eles!
        Agent.stop(bucket,:shutdown)
        assert KV.Registry.lookup(registry, "shopping") == :error
    end
end