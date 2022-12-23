defmodule Dispatcher do

  ###=============================================================================
  ### Main dispatcher, create and maintain the ring
  ###=============================================================================

  def initiate(host) do
    # spawn a new node
    Process.register(spawn(__MODULE__, :dispatch, [{:dispatcher, host}, []]), :dispatcher)
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

          _ ->
            # get next node, default first of the list
            # for now fix but should use hash
            nextnode = List.first(nodes)
            # send its own next node
            send({nname, nhost}, {:init, nextnode})
        end
        # add it in our ring
        dispatch({name, host}, [{nname, nhost}|nodes])

      {:addFile, {filename}} ->
        # store file in a random nodes
        # random for v0.1
        node = Enum.random(nodes)
        send(node, {:addFile, {filename}})
        dispatch({name, host}, nodes)

      {:requestFile, filename} ->
        # search a given file
        node = Enum.random(nodes)
        send(node, {:requestFileDis, filename, {name, host}})
        dispatch({name, host}, nodes)

      {:findFile, filename} ->
        # file was found
        IO.puts("#{filename} was found")
        dispatch({name, host}, nodes)

      {:filenotfound, filename} ->
        # file not found
        IO.puts("#{filename} was not found...")
        dispatch({name, host}, nodes)
    end
  end

  ###=============================================================================
  ### Default simple helper fct, lookFile not working for return (use of self)
  ###=============================================================================

  def addFile(filename) do
    send(:dispatcher, {:addFile, {filename}})
  end

  def lookFile(filename) do
    send(:dispatcher, {:requestFile, filename})
  end

end
