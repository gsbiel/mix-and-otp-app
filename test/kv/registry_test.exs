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
end