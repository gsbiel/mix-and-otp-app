defmodule KV.Registry do
    @moduledoc """
        Observações importantes:
        - GenServer é um módulo do tipo Behavior. Logo, as funções dessa API, para serem usadas, devem ser implementadas! No caso, implementamos as funções init, handle_call e handle_cast etc..., mas existem outras callbacks que asseguram a inicialização, finalização e o gerenciamento das requests do servidor.
        - Uma interação entre um cliente e esse servidor, de forma grosseira, poderia se dar da seguinte forma:
            >> {:ok, registry} = GenServer.start_link(KV.Registry, :ok)
                R: {:ok, #PID<x.xxx.x>}
            >> GenServer.cast(registry, {:create, "shopping"})
                R: :ok
            >> {:ok, bk} = GenServer.call(registry, {:lookup, "shopping"})
                R: {:ok, #PID<y.yyy.y>} }
        - A função cast() é assíncrona. Isso significa que tão logo a mensagem é enviada para o sevidor, o cliente volta às suas operações e segue o código em seu lado.
        - A função call() é síncrona, isso significa que o cliente fica parado esperando a resposta do servidor, para, só depois, seguir com o código em seu lado.
        - As chamadas da API fora usadas explicitamente, mas, no geral, é uma boa prática modularizar elas, isto é, criar um módulo e envelopar as implementações dessas chamadas em funções desse módulo. Assim, ao se implementar um GenServer, temos que pensar em duas partes: a implementação das callbacks do servidor e a implementação da API disponível para o cliente. Isso pode ser feito em arquivos separados, ou em um mesmo arquivo, como foi feito abaixo
    """
    use GenServer

    ## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ## Client API 
    ## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    @doc """
    Starts the registry
    """
    def start_link(opts) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    @doc """
    Looks up the bucket pid for "name" stored in "server".
    Returns "{:ok, pid}" if the bucket exists, ":error" otherwise.
    """
    def lookup(server,name) do
        GenServer.call(server, {:lookup,name})
    end

    @doc """
    Ensures there is a bucket associated with the given "name" in "server"
    """
    def create(server,name) do
        GenServer.cast(server, {:create, name})
    end

    ## -----------------------------------------------------------------------
    ## Server API
    ## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    @impl true
    def init(:ok) do
        {:ok, %{}}
    end

    @impl true
    def handle_call({:lookup,name}, _from, names) do
        {:reply, Map.fetch(names, name), names}
    end

    @impl true
    def handle_cast({:create, name}, names) do
        if Map.has_key?(names, name) do
            {:noreply, names}
        else
            {:ok, bucket} = KV.Bucket.start_link([])
            {:noreply, Map.put(names, name, bucket)}
        end
    end
    ## -----------------------------------------------------------------------


end