name              "annot-nf"
maintainer        "Thomas Otto"
maintainer_email  "iii-companion@glasgow.ac.uk"
license           "ISC"
description       "Installs annot-nf"
version           "1.0"

recipe "annot-nf", "Installs annot-nf from git"

%w{ ubuntu debian }.each do |os|
 supports os
end

%w{ git dockerio }.each do |cb|
 depends cb
end
