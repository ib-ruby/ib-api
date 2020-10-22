require 'integration_helper'

describe 'Request Fundamental Data',
         :connected => true, :integration => true, :reuters => true do

  before(:all) do
		establish_connection 
    ib = IB::Connection.current

    contract = IB::Contract.new :symbol => 'IBM',
                                 :exchange => 'NYSE',
                                 :currency => 'USD',
                                 :sec_type => 'STK'

    ib.send_message :RequestFundamentalData,
                     :id => 456,
                     :contract => contract,
                     :report_type => 'snapshot' # 'estimates', 'finstat'

    ib.wait_for :FundamentalData, 20 # sec
  end

#  after(:all){ close_connection }

  subject { IB::Connection.current.received[:FundamentalData].first }

  it { expect( IB::Connection.current.received[:FundamentalData]).to  have_at_least(1).data_message }

  it { is_expected.to be_an IB::Messages::Incoming::FundamentalData }
  its(:request_id) { is_expected.to eq 456 }
  its(:xml) { is_expected.to  be_a Hash }

  it 'responds with XML with relevant data' do
    require 'ox'
    data_xml = subject.xml[:ReportSnapshot]
    name = data_xml[:CoIDs][:CoID].at(1) 
    expect(name).to match 'International Business Machines'
  end
end

##pp  data_xml
#
#{:ReportSnapshot=>
#  {:CoIDs=>
#    {:CoID=>
#      ["4741N",
#       "International Business Machines Corp.",
#       "130871985",
#       "0000051143"]},
#   :Issues=>
#    {:Issue=>
#      [{:IssueID=>
#         ["Ordinary Shares", "IBM", "IBM", "IBM.N", "261483", "1090370"],
#        :Exchange=>"New York Stock Exchange",
#        :MostRecentSplit=>"2.0"},
#       {:IssueID=>
#         ["Preference Shares Series A",
#          "IBMPP",
#          "IBMPP.PK^C06",
#          "1883112",
#          "25545447"],
#        :Exchange=>"Over The Counter"}]},
#   :CoGeneralInfo=>
#    {:CoStatus=>"Active",
#     :CoType=>"Equity Issue",
#     :LastModified=>"2020-09-15",
#     :LatestAvailableAnnual=>"2019-12-31",
#     :LatestAvailableInterim=>"2020-06-30",
#     :Employees=>"352600",
#     :SharesOut=>"890578748.0",
#     :CommonShareholders=>"380707",
#     :ReportingCurrency=>"U.S. Dollars",
#     :MostRecentExchange=>"1.0"},
#   :TextInfo=>
#    {:Text=>
#      ["International Business Machines Corporation (IBM) is a technology company. The Company operates through five segments: Cognitive Solutions, Global Business Services (GBS), Technology Services & Cloud Platforms, Systems and Global Financing. The Cognitive Solutions segment delivers a spectrum of capabilities, from descriptive, predictive and prescriptive analytics to cognitive systems. Cognitive Solutions includes Watson, a cognitive computing platform that has the ability to interact in natural language, process big data, and learn from interactions with people and computers. The GBS segment provides clients with consulting, application management services and global process services. The Technology Services & Cloud Platforms segment provides information technology infrastructure services. The Systems segment provides clients with infrastructure technologies. The Global Financing segment includes client financing, commercial financing, and remanufacturing and remarketing.",
#       "BRIEF: For the six months ended 30 June 2020, International Business Machines Corp. revenues decreased 4% to $35.69B. Net income applicable to common stockholders excluding extraordinary items decreased 37% to $2.69B. Revenues reflect Global Technology Services segment decrease of 7% to $12.78B, Other segment decrease of 87% to $112M, Americas segment decrease of 4% to $16.62B, Europe/Middle East/Africa segment decrease of 6% to $11.21B."]},
#   :contactInfo=>
#    {:streetAddress=>["1 New Orchard Rd", nil, nil],
#     :city=>"ARMONK",
#     :"state-region"=>"NY",
#     :postalCode=>"10504-1722",
#     :country=>"United States",
#     :contactName=>nil,
#     :contactTitle=>nil,
#     :phone=>
#      {:phone=>
#        {:countryPhoneCode=>"1",
#         :"city-areacode"=>"914",
#         :number=>"4991900"}}},
#   :webLinks=>{:webSite=>"https://www.ibm.com/", :eMail=>nil},
#   :peerInfo=>
#    {:IndustryInfo=>
#      {:Industry=>
#        ["IT Services & Consulting - NEC",
#         "Computer Systems Design Services",
#         "Software Publishers",
#         "Custom Computer Programming Services",
#         "Electronic Computer Manufacturing",
#         "Semiconductor and Related Device Manufacturing",
#         "Other Computer Peripheral Equipment Manufacturing",
#         "Sales Financing",
#         "Office Machinery and Equipment Rental and Leasing",
#         "Data Processing Services",
#         "Computer Integrated System Design",
#         "Prepackaged Software",
#         "Computer Programming Services",
#         "Electronic Computers",
#         "Semiconductors/related Devices",
#         "Computer Periph'L Equipment, Nec",
#         "Misc Business Credit Institutions",
#         "Equipment Rental & Leasing, Nec",
#         "Data Processing And Preparation"]},
#     :Indexconstituet=>["S&P 500", "Dow Industry"]},
#   :officers=>
#    {:officer=>
#      [{:firstName=>"Virginia",
#        :mI=>"M.",
#        :lastName=>"Rometty",
#        :age=>"62 ",
#        :title=>"Executive Chairman of the Board"},
#       {:firstName=>"James",
#        :mI=>"M.",
#        :lastName=>"Whitehurst",
#        :age=>"52 ",
#        :title=>"President"},
#       {:firstName=>"Arvind",
#        :mI=>nil,
#        :lastName=>"Krishna",
#        :age=>"57 ",
#        :title=>"Chief Executive Officer, Director"},
#       {:firstName=>"James",
#        :mI=>"J.",
#        :lastName=>"Kavanaugh",
#        :age=>"53 ",
#        :title=>
#         "Senior Vice President, Chief Financial Officer, Finance and operation"},
#       {:firstName=>"Diane",
#        :mI=>"J.",
#        :lastName=>"Gherson",
#        :age=>"62 ",
#        :title=>"Chief Human Resource Officer, Senior Vice President"},
#       {:firstName=>"John",
#        :mI=>"E.",
#        :lastName=>"Kelly",
#        :age=>"66 ",
#        :title=>"Executive Vice President"},
#       {:firstName=>"Michelle",
#        :mI=>"H.",
#        :lastName=>"Browdy",
#        :age=>"55 ",
#        :title=>
#         "Senior Vice President - Legal and Regulatory Affairs and General Counsel"},
#       {:firstName=>"Kenneth",
#        :mI=>"M.",
#        :lastName=>"Keverian",
#        :age=>"63 ",
#        :title=>"Senior Vice President - Corporate Strategy"},
#       {:firstName=>"Robert",
#        :mI=>"F.",
#        :lastName=>"Del Bene",
#        :age=>"60 ",
#        :title=>"Vice President, Controller"}]},
#   :Ratios=>
#    {:Group=>
#      [{:Ratio=>
#         ["125.94000",
#          "158.75000",
#          "90.56000",
#          "2020-10-14T00:00:00",
#          "6.32897",
#          "162793.50000"]},
#       {:Ratio=>["112159.50000", "75499.00000", "17859.00000", "8020.00000"]},
#       {:Ratio=>
#         ["8.97154",
#          "84.43922",
#          "23.07601",
#          "15.83689",
#          "16.38814",
#          "6.49000"]},
#       {:Ratio=>
#         ["47.75957",
#          "41.99393",
#          "1.48558",
#          "14.03772",
#          "5.45762",
#          "352600"]}]},
#   :ForecastData=>
#    {:Ratio=>
#      [{:Value=>"2.6111"},
#       {:Value=>"135.31250"},
#       {:Value=>"2.5700"},
#       {:Value=>"11.37865"},
#       {:Value=>"74022.22230"},
#       {:Value=>"17542.17620"},
#       {:Value=>"11.06810"},
#       {:Value=>"2.58030"},
#       {:Value=>"9856.58830"},
#       {:Value=>"6.49000"}]}}}
# 
