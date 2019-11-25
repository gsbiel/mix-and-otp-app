defmodule KV.Supervisor do
    @moduledoc """
    Esse supervisor é responsável por iniciar todos os processos declarados como filhos. No caso, vamos supervisionar o processo KV.Registry, que armazena todos os buckets da aplicação. Isso é fundamental, pois se esse processo para, não será possível acessar nenhum bucket!
    A estratégia de supervisão é one_for_one, o que significa que se um dos filhos parar de funcionar, apenas ele que vai ser reiniciado.

    A abordagem de se utilizar supervisores é muito poderosa, pois libera o desenvolvedor de se preocupar com programação defensiva, o que é muito custoso. Assim, ele só se preocupa com as funcionalidades básicas e qualquer erro que acontecer terminará com o processo sendo reiniciado automaticamente.
    """
    use Supervisor

    def start_link(opts) do
        Supervisor.start_link(__MODULE__, :ok, opts)

    end

    @impl true
    def init(:ok) do
        children = [
            {KV.Registry, name: KV.Registry}
        ]
        Supervisor.init(children, strategy: :one_for_one)
    end
end