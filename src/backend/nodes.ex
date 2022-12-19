defmodule Nodee do

  ###=============================================================================
  ### Basics node creation
  ###=============================================================================

  def winit(person) do
    spawn(__MODULE__, :nodee, person)
  end

  def nodee({id, name}) do
    import Communication

    receive do
      {:init, nextNode} ->
        IO.puts("Initiating...")
        ringReceive({id, name}, nextNode, [], [])
    end

  end

end
