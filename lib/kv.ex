defmodule KV do
  @moduledoc """
  Sempre que abrimos o terminal interativo do elixir (iex -S mix), nossa 
  aplicação é compilada. Assim, podemos consumir as API's dos módulos que
  foram implementados. Como você sabe, temos, até agora, um módulo que
  implementa os buckets, um módulo que gerencia e registra os buckets 
  e um módulo que supervisiona esse registro de buckets (inicia os processos e reinicia quando um deles quebra).
  A questão é, quem inicia o processo supervisor? quem deve fazer isso é a aplicação,
  assim que for iniciada. Para isso, implementamos uma callback que é chamada assim que a aplicação termina de
  compilar os módulos. No arquivo de definição do projeto (mix.exs), configuramos o nome do módulo que implementa 
  a rotina de callback (que é este aqui, kv.ex). Neste módulo, implementamos a rotina, na função start.
  Essa função basicamente inicia o supervisor que está no topo da árvore de supervisão.
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    KV.Supervisor.start_link(name: KV.Supervisor)
  end
end
