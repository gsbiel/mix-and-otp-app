defmodule KV.Bucket do
    @moduledoc """
    Ao se interagir com a API do módulo Agent, não é interessante espalhar as funções do módulo ao longo dos arquivos do app. Então, uma boa prática é centralizar tudo em um módulo (costuma-se chamar ele de "Bucket"), e usar as funções desse módulo ao longo do app. 

    Uma coisa que se deve atentar é que, ao criar uma instância do Agent, criamos um processo que vai rodar em loop e armazenar as informações que queremos persistir.
    Quando interagimos com a API do Agent, estamos, na verdade, enviando e recebendo mensagens para o processo que está rodando em loop. Dizemos que esse processo atua como servidor. 
    A função anônima que passamos nas chamadas das API são executadas no lado do servidor. Isso significa que se você colocar muitas operações dentro da função anônima, o processo vai ficar ocupado com ela e só vai atender requisições de outros clientes após ter terminado todas as operações. Enquanto ele processa, os outros clientes ficam aguardando e podem acabar entrando em timeout.
    Por isso, seja sábio ao definir o que vai ser executado no lado do servidor (dentro da função anônima) e o que vai ser executado no lado cliente (fora da função anônima, isto é, antes de se fazer a chamada da API).

    Essa forma de se operar com estados é muito crua por dois motivos: 
        1) Veja que o Bucket criado não tem nome. E se quiséssemos ter vários Buckets diferentes,  cada um persistindo dados de diferentes categorias? Ao se interagir com a API do Agent você até poderia passar um nome (um atom) para uma instância do Agent, que passaria a ser identificada por esse nome. MAS ISSO SERIA UMA MÁ IDEIA! Pois Existe um limite de atoms que podem ser declarados. Isso causaria uma vulnerabilidade, pois um cliente poderia ficar solicitando a criação de diferentes buckets até esgotar esse limite, o que resultaria em um crash da aplicação!
        2) Com relação a erros, caso um dos buckets pare de funcionar devido a algum bug nenhuma parte do app vai saber que isso aconteceu, pois não há nenhum tipo de monitoramento quanto a isso.
    Esses problemas são resolvidos por um processo que abstrai tudo isso, conhecido como "GenServer", além de deixar a relação cliente/servidor mais explícita.
    """
    use Agent

    @doc """
    Starts a new bucket.
    _opts é uma lista de parâmetros opcionais que podem ser passados para a função start_link, de modo a influenciar alguma operação na hora de criar o estado.
    """
    def start_link(_opts) do
        Agent.start_link(fn -> %{} end)
    end

    @doc """
    Obter um valor do "Bucket" a partir de uma "key"
    """
    def get(bucket, key) do
        Agent.get(bucket, fn bucket -> Map.get(bucket, key) end )
    end

    @doc """
    Inserir um valor, identificado por uma "key", dentro do "Bucket"
    """
    def put(bucket, key, value) do
        Agent.update(bucket, fn bucket -> Map.put(bucket, key, value) end )
    end

    @doc """
    Deletar um valor do "bucket", a partir de uma "key"
    """
    def delete(bucket, key) do
        Agent.get_and_update(bucket, fn bucket -> Map.pop(bucket, key) end)
    end


end