function usage()
  io.stderr:write(string.format("Usage: %s <GFF annotation> <seqfile>\n" , arg[0]))
  os.exit(1)
end

if #arg < 2 then
  usage()
  os.exit(1)
end

rm = gt.region_mapping_new_seqfile(arg[2])

cv = gt.custom_visitor_new()
cv.nof_genes = 0
cv.nof_trnas = 0
cv.nof_coding_genes = 0
cv.nof_genes_with_introns = 0
cv.nof_genes_with_function = 0
cv.nof_genes_with_transferred = 0
cv.nof_singleton_genes = 0
cv.nof_singleton_genes_with_function = 0
cv.nof_regions = 0
cv.nof_chromosomes = 0
cv.overall_length = 0
cv.coding_length = 0
cv.gc_overall = 0
cv.gc_coding = 0
function cv:visit_feature(fn)
  local seqid = fn:get_seqid()
  if fn:get_type() == 'gene' then
    local nof_exons = 0
    local coding = false
    cv.nof_genes = cv.nof_genes + 1
    for n in fn:get_children() do
      if n:get_type() == 'mRNA' then
        if not coding then
          coding = true
        end
        -- calculate coding GC content
        local seq = string.lower(n:extract_sequence('CDS', true, rm))
        for c in seq:gmatch("[gc]") do
          cv.gc_coding = cv.gc_coding + 1
        end
        for c in seq:gmatch("[agct]") do
          cv.coding_length = cv.coding_length + 1
        end
      elseif n:get_type() == 'tRNA' then
        cv.nof_trnas = cv.nof_trnas + 1
      elseif n:get_type() == 'CDS' then
        nof_exons = nof_exons + 1
      end
    end
    -- is coding?
    if coding then
      cv.nof_coding_genes = cv.nof_coding_genes + 1
    end
    -- has more than one exon?
    if nof_exons > 1 then
      cv.nof_genes_with_introns = cv.nof_genes_with_introns + 1
    end
  elseif fn:get_type() == 'polypeptide' then
    local orths = fn:get_attribute("orthologous_to")
    local product = fn:get_attribute("product")
    -- is species-specific?
    if not orths then
      cv.nof_singleton_genes = cv.nof_singleton_genes + 1
    end
    -- has defined function?
    if product and not string.match(product, "hypothetical") then
      cv.nof_genes_with_function = cv.nof_genes_with_function + 1
      if not orths then
        cv.nof_singleton_genes_with_function = cv.nof_singleton_genes_with_function + 1
      end
      -- function transferred from reference?
      if string.match(product, 'with.3DGeneDB:') then
        cv.nof_genes_with_transferred = cv.nof_genes_with_transferred + 1
      end
    end
  end

  return 0
end
function cv:visit_region(rn)
  local seqid = rn:get_seqid()
  cv.nof_regions = cv.nof_regions + 1
  -- how many sequences are full chromosomes?
  if string.match(seqid, '^[^.]+_[0-9]+') then
    cv.nof_chromosomes = cv.nof_chromosomes + 1
  end
  return 0
end
function cv:visit_sequence(sn)
  local seq = string.lower(sn:get_sequence())
  -- calculate overall GC content
  for c in seq:gmatch("[gc]") do
    cv.gc_overall = cv.gc_overall + 1
  end
  for c in seq:gmatch("[agtc]") do
    cv.overall_length = cv.overall_length + 1
  end
  return 0
end
function cv:calc_gc_overall()
  return (cv.gc_overall/cv.overall_length)
end
function cv:calc_gc_coding()
  return (cv.gc_coding/cv.coding_length)
end

-- tool code here

stats_stream = gt.custom_stream_new_unsorted()
stats_stream.instream = gt.gff3_in_stream_new_sorted(arg[1])
stats_stream.visitor = cv
function stats_stream:next_tree()
  local node = self.instream:next_tree()
  if node then
    node:accept(self.visitor)
  end
  return node
end

local gn = stats_stream:next_tree()
while (gn) do
  gn = stats_stream:next_tree()
end

print("nof_regions: " .. cv.nof_regions)
print("nof_chromosomes: " .. cv.nof_chromosomes)
print("overall_length: " .. cv.overall_length)
print("gc_overall: " .. string.format("%.2f", cv:calc_gc_overall()*100))

print("nof_genes: " .. cv.nof_genes)
print("gene_density: " .. string.format("%.2f", cv.nof_coding_genes/(cv.overall_length/1000000)))
print("avg_coding_length: " .. string.format("%d", cv.coding_length/cv.nof_genes))
print("nof_coding_genes: " .. cv.nof_coding_genes)
print("nof_genes_with_introns: " .. cv.nof_genes_with_introns)
print("nof_genes_with_function: " .. cv.nof_genes_with_function)
print("nof_genes_with_transferred\: " .. cv.nof_genes_with_transferred)
print("nof_trnas: " .. cv.nof_trnas)
print("gc_coding: " .. string.format("%.2f", cv:calc_gc_coding()*100))

print()
print(cv.nof_genes-cv.nof_coding_genes) -- non-coding
print(cv.nof_coding_genes-cv.nof_genes_with_function) -- hypothetical
print(cv.nof_genes_with_function-cv.nof_genes_with_transferred) -- non-transferred
print(cv.nof_genes_with_transferred) -- transferred
