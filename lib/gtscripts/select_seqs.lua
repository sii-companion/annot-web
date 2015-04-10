function usage()
  io.stderr:write(string.format("Usage: %s <seqfile> <pattern>\n" , arg[0]))
  os.exit(1)
end

if #arg < 2 then
  usage()
end

function get_fasta(filename, sep)
  local keys = {}
  local seqs = {}
  local cur_hdr = nil
  local cur_seqs = {}
  for l in io.lines(filename) do
    hdr = l:match(">(.*)")
    if hdr then
      table.insert(keys, hdr)
      if #cur_seqs > 0 and cur_hdr then
        if not seqs[cur_hdr] then
          seqs[cur_hdr] = table.concat(cur_seqs, sep)
        end
      end
      cur_hdr = hdr
      cur_seqs = {}
    else
      table.insert(cur_seqs, l)
    end
  end
  if cur_hdr and not seqs[cur_hdr] then
    seqs[cur_hdr] = table.concat(cur_seqs, sep)
  end
  return keys, seqs
end

function get_fasta_nosep(filename)
  return get_fasta(filename, "")
end

seqkeys, seqs = get_fasta_nosep(arg[1])

table.sort(seqkeys)
for _,k in ipairs(seqkeys) do
  if k:match(arg[2]) then
    print('>'..k)
    print(seqs[k])
  end
end