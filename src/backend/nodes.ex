defmodule Nodee do

  ###=============================================================================
  ### Basics node creation
  ###=============================================================================

  def node_init({name, host}, dispatcher) do
    # spawn a new node
    spawn(__MODULE__, :nodee, [{name, host}, dispatcher])
  end

  def nodee({name, host}, dispatcher) do
    # wait for next node to be known, then wait for other message
    import Communication

    send(dispatcher, {:incoming, {name, host}})

    receive do
      {:initfirst} ->
        IO.puts("Initiating first one...")
        appearancefirst({name, host})
      {:init, nextNode} ->
        IO.puts("Initiating...")
        appearance({name, host}, nextNode)
    end
  end
end
