# best-practices

Document how to make best practices project structure 


Find more details about project structure on GenomeDK – Best practices (https://genome.au.dk/docs/best-practices/).


## Top-level layout
project_root/
├── README.md -> .admin/backup/README.md
├── PrimaryData/	# Immutable raw input data
├── DerivedData/	# Reproducible processed data
├── WorkSpaces/		# User analysis and development
└── .admin/			# Project administration

## .admin (project administration)
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


## PrimaryData (raw data)
* Read-only after deposition
* Never edited
* Controlled access
* Loss is catastrophic

PrimaryData
├── README.md -> backup/README.md
└── backup
    └── README.md

## DerivedData (processed samples)
* Reproducible from PrimaryData
* Shared across users
* Should not contain ”personal experiments”

DerivedData
├── README.md -> backup/README.md
├── backup/
│   └── README.md
├── main/
├── manifest/
├── qc/
└── reference/

## WorkSpaces (one for each user)
* Can run experiments freely
* Can break things locally without harming others
* No contamination of shared materials

### WorkSpaces/<username>

<username>/
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


