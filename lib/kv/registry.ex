defmodule KV.Registry do
    @moduledoc """
        Observações importantes:
        - GenServer é um módulo do tipo Behavior. Logo, as funções dessa API, para serem usadas, devem ser implementadas! No caso, implementamos as funções init, handle_call, handle_cast e handle_info etc..., mas existem outras callbacks que asseguram a inicialização, finalização e o gerenciamento das requests do servidor.
        - Uma interação entre um cliente e esse servidor, de forma grosseira, poderia se dar da seguinte forma:
            >> {:ok, registry} = GenServer.start_link(KV.Registry, :ok)
                R: {:ok, #PID<x.xxx.x>}
            >> GenServer.cast(registry, {:create, "shopping"})
                R: :ok
            >> {:ok, bk} = GenServer.call(registry, {:lookup, "shopping"})
                R: {:ok, #PID<y.yyy.y>} }
        - A função cast() é assíncrona. Isso significa que tão logo a mensagem é enviada para o sevidor, o cliente volta às suas operações e segue o código em seu lado.
        - A função call() é síncrona, isso significa que o cliente fica parado esperando a resposta do servidor, para, só depois, seguir com o código em seu lado.
        - As chamadas da API fora usadas explicitamente, mas, no geral, é uma boa prática modularizar elas, isto é, criar um módulo e envelopar as implementações dessas chamadas em funções desse módulo. Assim, ao se implementar um GenServer, temos que pensar em duas partes: a implementação das callbacks do servidor e a implementação da API disponível para o cliente. Isso pode ser feito em arquivos separados, ou em um mesmo arquivo, como foi feito abaixo.

        Sobre a função Handle_Info:
        >> {:ok, pid} = KV.Bucket.start_link([])
            R: {:ok, #PID<x.xx.x>} -> Essa é a referência do processo que iniciamos para armazenar o estado do app, usando o módulo KV.Bucket
        >> Process.monitor(pid) -> Estamos inicializando um processo supervisor que vai monitorar o processo que iniciamos no comando anterior.
            R: #Reference<y.y.y.yyy> -> o comando retornar a referência para esse supervisor
        >> Agent.stop(pid) -> Estamos mandando o processo referênciado pela variável "pid" parar imediatamente.
            R: :ok
        >> flush()
            R: {:DOWN, #Reference<y.y.y.yyy>, :process, #PID<x.xx.x>, :normal}
            Ao fecharmos o processo "pid", o processo supervisor recebeu uma mensagem identificada por :DOWN, informando que o processo #PID<x.xx.x> foi fechado por causa normal. Note que sem o processo supervisor, nunca saberíamos que o processo "pid" foi parado.
        Um a observação importante sobre isso é que se houver conteúdo no estado gerenciado pelo processo pid, esse conteúdo não será apagado! Para limpar esse conteúdo temos que detectar o fechamento do processo e implementar o código necessário para tal. É aí que entra a função handle_info().

    """
    use GenServer

    ## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
    ## Client API 
    ## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
    
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

    ## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
    ## Server API
    ## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    @impl true
    def init(:ok) do
        names= %{}
        refs = %{}
        {:ok, {names, refs}}
    end

    @impl true
    def handle_call({:lookup,name}, _from, state) do
        {names, __} = state
        {:reply, Map.fetch(names, name), state}
    end

    @impl true
    def handle_cast({:create, name}, {names, refs}) do
        if Map.has_key?(names, name) do
            {:noreply, {names,refs}}
        else
            # Ao se criar um novo bucket (que é um processo), deve-se criar também um processo supervisor para o mesmo.
            {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
            ref = Process.monitor(pid)
            # No mapa de referências dos supervisores, a referência do supervisor aponta para o nome do bucket que o mesmo supervisiona.
            refs = Map.put(refs, ref, name)
            # No mapa de nomes dos buckets, o nome aponta para a referência do bucket (processo)
            names = Map.put(names, name, pid)
            {:noreply, {names, refs} }
        end
    end

    @doc """
    Essa callback é executada sempre que mensagens chegam ao GenServer, que não seja calls and casts. Nesse caso, estamos interessados apenas em interceptar as mensagens indicando a queda de um dos buckets, pois, nessa situação temos que remover esse bucket, agora vazio, do nosso registro de buckets.
    """
    @impl true
    def hande_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
        # Remove do mapa "refs" a chave "ref" (processo monitor) e retorna o valor que estava nela antes da remoção que, no caso, é o nome do bucket (processo que estava sendo monitorado).
        {name, refs} = Map.pop(refs,ref)
        # Remove do mapa "names" o par chave-valor correspondente a "name"
        names = Map.delete(names,name)
        {:noreply, {names, refs}}
    end

    @impl true
    def handle_info(_msg, state) do
        {:noreply, state}
    end
    ## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
end