# Best practices in structuring research projects

This repository documents how to apply good practices in structuring research projects with emphasis on multi-user projects.

Find more details about project structure on GenomeDK – Best practices (https://genome.au.dk/docs/best-practices/).


## Directory layout 
### Top-level layout

	project_root/
	├── README.md -> .admin/backup/README.md
	├── PrimaryData/	# Immutable raw input data
	├── DerivedData/	# Reproducible processed data
	├── WorkSpaces/		# User analysis and development
	└── .admin/			# Project administration

### .admin (project administration)
Project governance

	.admin/  
	├── backup/  
	│   └── README.md  
	├── scripts/  
	│   └── setup/  
	│       ├── setup_new_project.sh  
	│       └── setup_utils.sh  
	└── logs/  
	    └── setup_new_project_<timestamp>.log


### PrimaryData (raw data)
Read-only after deposition. 
Never edited. 
Controlled access. 
Loss is catastrophic. 


	PrimaryData  
	├── README.md -> backup/README.md  
	└── backup  
    	└── README.md  



### DerivedData (processed samples)
Reproducible from PrimaryData.
Shared across users.
Should not contain ”personal experiments”.

	DerivedData  
	├── README.md -> backup/README.md  
	├── backup/  
	│   └── README.md  
	├── main/  
	├── manifest/  
	├── qc/  
	└── reference/  

### WorkSpaces (each user has a subdirectory)
Can run experiments freely.
Can break things locally without harming others.
No contamination of shared materials.

#### WorkSpaces/\<username\>

	<username>
	├── README.md -> backup/README.md
	├── environment.yml -> backup/environment.yml
	├── backup/
	│   ├── README.md
	│   ├── environment.yml
	│   ├── scripts/
	│   └── plots/	# scripts to plot and resulting plots
	├── data/ 		# user-specific raw data or symlinks to DerivedData
	├── steps/		# intermediate data
	└── results/	# final data files



## Naming data files

Structure main data subdirectories from many individuals each with multiple samples.

	DerivedData
	└── <individualID>
		└── <sampleID>_<specimenType>_<batchID>
			├── <sampleID_C>_<specimen>.<properties>.<ext>
			└── workflow
				├── account.txt		# HPC account info
				├── conda.yaml		# environment
				├── README.md
				├── .gwfconf.json	# configuration
				├── ...
				└── workflow.py		# workflow file


Examples

	DerivedData
	├── NGS				# Example for NGS data
	│	└── I01234		# indivudualID
	│		├── S001I01234D_ffpe_B01-001	
	│		│	├── S001I01234D_ffpe.aligned.sorted.markdup.bam
	│		│	├── S001I01234D_ffpe.aligned.sorted.markdup.bam.bai
	│		│	├── S001I01234D_ffpe.multiqc.report.html
	│		│	├── S001I01234D_ffpe.mutect.filtered.vcf.gz
	│		│	├── S001I01234D_ffpe.mutect.filtered.vcf.gz.tbi
	│		│	└── S001I01234D_ffpe.wgs_metrics.txt
	│		└── S002I01234D_buffycoat_B01-002
	│			├── S002I01234D_buffycoat.aligned.sorted.markdup.bam
	│			├── S002I01234D_buffycoat.aligned.sorted.markdup.bam.bai
	│			├── S002I01234D_buffycoat.haplotypecaller.filtered.vcf.gz
	│			├── S002I01234D_buffycoat.haplotypecaller.filtered.vcf.gz.tbi
	│			├── S002I01234D_buffycoat.multiqc.report.html
	│			└── S002I01234D_buffycoat.wgs_metrics.txt
	└── ONT
		└── I01234
			└── S003I01234D_frfr_B02-001
				├── S003I01234D_frfr.aligned.phased.bam
				├── S003I01234D_frfr.aligned.phased.bam.bai
				├── S003I01234D_frfr.clair3.vcf.gz
				├── S003I01234D_frfr.clair3.vcf.gz.tbi
				├── S003I01234D_frfr.cutesv.vcf.gz
				└── S003I01234D_frfr.cutesv.vcf.gz.tbi





