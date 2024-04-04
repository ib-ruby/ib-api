Changelog
=============

| Date   |  Description |
|=++++   |=++++++++++++ |
| 30.8.2020 | migrating lib-files from ib-ruby-project |

| 28.11.2020| separating lib/model and lib/models to enable extension with
              ActiveRecord/Rails and OrientDB/ActiveOrient. |
|           | Introducing a Database-Switch in /lib/requires to omit 
              loading of model- and messages files. This has to be done 
							manually after assigning the database-model framework. |

| 1.12.2020 | moving model/ib/spread.rb from `ib-extensions` to `ib-api`.|
| 1.12.2020 | creating a dummy Contract#verify to guaranty safe operation of spreads |

|           | Preparation of a Gem-Release  |
| 23.2.2021 | Fixed retrieving of ContractDetail requests of Options with strikes < 1 
|           | Gem Release                   |

|  1.4.2024 | Proper monkey patching of classes through class_extensions (Prepare for Zeitwerk, V10)
|  2.4.2024 | Renaming of IBSupport and IBSocket to IB::Support and IB::Socket (Prepare for Zeitwerk, V10)
|  4.4.2024 | Apply Zeitwerk, V10
              Put `model` to the root directory (the files are then easily fetched through zeitwerk)
              Reorganizing Messages. One message class per file. Keeping general incoming and outgoing-files
