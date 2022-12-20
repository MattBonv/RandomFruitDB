defmodule Dispatcher do

  ###=============================================================================
  ### Main dispatcher, create and maintain the ring
  ###=============================================================================

  def initiate({name, host}) do
    # spawn a new node
    spawn(__MODULE__, :dispatch, [{name, host}, []])
  end

  def dispatch({name, host}, nodes) do
    # wait for new nodes
    receive do
      {:incoming, {nname, nhost}} ->
        # new node incoming
        l = length(nodes)
        case l do
          0 ->
            # nothing, waiting for the next one
            send({nname, nhost}, {:initfirst})

          1 ->
            # exchange
            othernode = List.first(nodes)
            # send its own next node
            send({nname, nhost}, {:init, othernode})

          _ ->
            # get next node, default first of the list
            # for now fix but should use hash
            nextnode = List.first(nodes)
            # send its own next node
            send({nname, nhost}, {:init, nextnode})
        end

        # add it in our ring
        dispatch({name, host}, [{nname, nhost}|nodes])
    end
  end

  ###=============================================================================
  ### Default simple helper fct, lookFile not working for return (use of self)
  ###=============================================================================

  def addFile({id, machine}, filename) do
    send({id, machine}, {:addFile, {filename}})
  end

  def lookFile({id, machine}, filename) do
    send({id, machine}, {:requestFile, filename {self(), self()}})
  end

end
