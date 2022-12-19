defmodule Communication do

  ###=============================================================================
  ### Basics inter-node communication
  ###=============================================================================

  def ringReceive({id, name}, nodes, ownfiles, searchingFiles) do
    # wait for msg reception
    # {id, name} : itself
    # nodes : known nodes, v0.1 -> only next one
    # ownfiles : list with file identifier that belong to this node
    # searchingFiles : list of {requID: filename:}
    #  -> avoid loop search
    #  -> retrieve where to send a file

    receive do
      {:addFile, {filename}} ->
        # add file in storage
        # done later
        IO.puts("New file #{filename}")
        ringReceive({id, name}, nodes, [filename | ownfiles], searchingFiles)

      {:requestFile, filename, sender} ->
        cond do
        List.keymember?(searchingFiles, filename, 1) ->
          # loop
          IO.puts("File #{filename} not found")
          send(sender, {:stopFile, filename})
          # should remove filename from searchingFiles
          ringReceive({id, name}, nodes, ownfiles, searchingFiles)
        Enum.member?(ownfiles, filename) ->
          # own file
          # TODO: retreive file and send
          IO.puts("Find file #{filename}")
          send(sender, {:findFile, filename})
          ringReceive({id, name}, nodes, ownfiles, searchingFiles)
        true ->
          # ask next node
          IO.puts("File #{filename} not found here")
          send(nodes, {:requestFile, filename, name})
          ringReceive({id, name}, nodes, ownfiles, [{sender, filename}|searchingFiles])
        end

      {:findFile, filename} ->
        # find who requested that file and send it
        {requester, _} = List.keyfind(searchingFiles, filename, 1)
        send(requester, {:findFile, filename})
        ringReceive({id, name}, nodes, ownfiles, searchingFiles)
    end
  end
end
