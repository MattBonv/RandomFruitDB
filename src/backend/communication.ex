defmodule Communication do

  ###=============================================================================
  ### Basics inter-node communication
  ###=============================================================================

  def sendFile({requester, mainrequest}, filename) do
    # this fct should retreive the data and send it to the requester
    send(requester, {:findFile, filename, mainrequest})
  end

  def ringReceive({name, host}, {nextnode, prevnode}, ownfiles) do
    # wait for msg reception
    # {id, name} : itself
    # nextnode : known nodes, v0.1 -> only next one
    # previousnode : known nodes, v0.1 -> only next one
    # ownfiles : list with file identifier that belong to this node

    receive do
      {:addFile, {filename}} ->
        # add file in storage
        # done later
        IO.puts("New file #{filename}")
        ringReceive({name, host}, {nextnode, prevnode}, [filename | ownfiles])

      {:requestFile, filename, requester}} ->
        # from dispatch
        if Enum.member?(ownfiles, filename) do
          # own file
          IO.puts("Find file #{filename}")
          sendFile({requester, mainrequest}, filename)
          ringReceive({name, host}, {nextnode, prevnode}, ownfiles)
        else
          send(nextnode, {:requestFile, filename, {{name, host}, requester}})
          ringReceive({name, host}, {nextnode, prevnode}, ownfiles)
        end

      {:requestFile, filename, {requester, mainrequest}} ->
        # looking for a file
        cond do
          requester == {name, host} ->
            # loop on the ring
            IO.puts("File #{filename} not found")
            send(mainrequest, {:filenotfound, filename})
            ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

          Enum.member?(ownfiles, filename) ->
            # own file
            IO.puts("Find file #{filename}")
            sendFile({requester, mainrequest}, filename)
            ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

          true ->
            # ask next node
            IO.puts("File #{filename} not found here")
            send(nextnode, {:requestFile, filename, {requester, mainrequest}})
            ringReceive({name, host}, {nextnode, prevnode}, ownfiles)
        end

      {:findFile, filename, mainrequest} ->
        # send the main one the found file
        send(mainrequest, {:findFile, filename})
        ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

      {:imprevious?, {pname, phost}} ->
        # send previous node
        send({pname, phost}, {:myprevious, prevnode})
        ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

      {:imprevious, {pname, phost}} ->
        # update nodes mode
        ringReceive({name, host}, {nextnode, {pname, phost}}, ownfiles)

      {:imnext?, {nname, nhost}} ->
        # send next node
        send({nname, nhost}, {:mynext, nextnode})
        ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

      {:imnext, {nname, nhost}} ->
        # update nodes mode
        ringReceive({name, host}, {{nname, nhost}, prevnode}, ownfiles)
    end
  end

  ###=============================================================================
  ### At startup, to get previous and next node on the ring
  ###=============================================================================

  def appearancefirst({name, host}) do
    # wait for another node
    receive do
      {:imprevious?, prevnode} ->
        # will be my previous
        send(prevnode, {:myprevious, prevnode})
        ringReceive({name, host}, {prevnode, prevnode}, [])
    end
  end

  def appearance({name, host}, nextnode) do
    # create its place
    send(nextnode, {:imprevious?, {name, host}})
    receive do
      {:myprevious, prevnode} ->
        # will be my previous
        send(nextnode, {:imprevious, {name, host}})
        send(prevnode, {:imnext, {name, host}})
        ringReceive({name, host}, {nextnode, prevnode}, [])
    end
  end

  ###=============================================================================
  ### During run, to keep and update the previous and next node
  ###=============================================================================

  def updateNext({name, host}, {nextnode, prevnode}, ownfiles) do
    # check if we are still the previous node for the following one
    send(nextnode, {:imprevious?, {name, host}})

    receive do
      {:myprevious, myprev} ->
        cond do
          myprev == {name, host} ->
            # we are, back to work
            ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

          myprev == prevnode ->
            # he missed me
            send(myprev, {:imprevious, {name, host}})
            ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

          true ->
            # then who are we
            updateNext({name, host}, {myprev, prevnode}, ownfiles)
        end
    end
  end

  def updatePrev({name, host}, {nextnode, prevnode}, ownfiles) do
    # check if we are still the next node for the previous one
    send(prevnode, {:imnext?, {name, host}})

    receive do
      {:mynext, mynext} ->
        cond do
          mynext == {name, host} ->
            # we are, back to work
            ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

          mynext == nextnode ->
            # he missed me
            send(mynext, {:imnext, {name, host}})
            ringReceive({name, host}, {nextnode, prevnode}, ownfiles)

          true ->
            # then who are we
            updatePrev({name, host}, {nextnode, mynext}, ownfiles)
        end
    end
  end
end
