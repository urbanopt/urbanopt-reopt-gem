(window.webpackJsonp=window.webpackJsonp||[]).push([[8],{374:function(e,t,a){},404:function(e,t,a){"use strict";a(374)},428:function(e,t,a){"use strict";a.r(t);a(404);var o=a(56),r=Object(o.a)({},(function(){var e=this,t=e.$createElement,a=e._self._c||t;return a("ContentSlotsDistributor",{attrs:{"slot-key":e.$parent.slotKey}},[a("h1",{attrs:{id:"reopt-lite-inputs-schema"}},[a("a",{staticClass:"header-anchor",attrs:{href:"#reopt-lite-inputs-schema"}},[e._v("#")]),e._v(" REopt Lite Inputs Schema")]),e._v(" "),a("p",[e._v("The following shows the complete set of inputs to the REopt Lite AP which is called internally by the REopt Gem. You may refer to the data dictionary below in creating similarly formatted .json files containing alternatives to the defaults for optional parameters (i.e. specific utility rate, installed cost assumptions, solar PV losses, ...). The URBANopt REopt Gem will overwrite latitude, longitude, land_acres, roof_squarefeet, and loads_kw where possible from attributes of a Scenario Report and FeatureReports.")]),e._v(" "),a("h2",{attrs:{id:"data-dictionary"}},[a("a",{staticClass:"header-anchor",attrs:{href:"#data-dictionary"}},[e._v("#")]),e._v(" Data Dictionary")]),e._v(" "),a("ReoptInputSchema"),e._v(" "),a("h2",{attrs:{id:"required-inputs"}},[a("a",{staticClass:"header-anchor",attrs:{href:"#required-inputs"}},[e._v("#")]),e._v(" Required Inputs")]),e._v(" "),a("p",[e._v("The only required parameters to the REopt Lite API (called internally by the gem) are:")]),e._v(" "),a("ul",[a("li",[a("p",[a("em",[e._v("latitude")])])]),e._v(" "),a("li",[a("p",[a("em",[e._v("longitude")])])]),e._v(" "),a("li",[a("p",[a("em",[e._v("urdb_response")]),e._v(" \t\nOr one of the following sets: "),a("em",[e._v("urdb_label")]),e._v("; "),a("em",[e._v("blended_monthly_rates_us_dollars_per_kwh")]),e._v("; "),a("em",[e._v("blended_annual_demand_charges_us_dollars_per_kw")]),e._v(" "),a("strong",[e._v("and")]),e._v(" "),a("em",[e._v("blended_annual_rates_us_dollars_per_kwh")])])]),e._v(" "),a("li",[a("p",[a("em",[e._v("loads_kw")])]),e._v(" "),a("p",[e._v("Or one of the following sets: "),a("em",[e._v("doe_reference_name")]),e._v(" "),a("strong",[e._v("and")]),e._v(" "),a("em",[e._v("annual_kwh")]),e._v(", "),a("em",[e._v("doe_reference_name")]),e._v(" "),a("strong",[e._v("and")]),e._v(" "),a("em",[e._v("monthly_totals_kwh")])])])]),e._v(" "),a("p",[e._v("The gem sources "),a("em",[e._v("latitude")]),e._v(", "),a("em",[e._v("longitude")]),e._v(" and "),a("em",[e._v("loads_kw")]),e._v(" from a Feature or Scenario Report directly. If no specific "),a("em",[e._v("urdb_response")]),e._v(" or "),a("em",[e._v("urdb_label")]),e._v(" is specified as an custom assumption (see below), then a constant rate of $0.13/kWh with no demand charge is provided by the gem as a default to the REopt API.")]),e._v(" "),a("p",[e._v("Otherwise, all non-required input parameters will be filled in with default values unless otherwise specified. For an example of a minimally viable REopt Lite input, see:")]),e._v(" "),a("div",{staticClass:"language- extra-class"},[a("pre",{pre:!0,attrs:{class:"language-text"}},[a("code",[e._v('{\t\n\t"Scenario": {\n\t\t"Site":{\n\t\t\t"latiude":45,\n\t\t\t"longitude":-110,\n\t\t\t"ElectricTariff": {\n\t\t\t\t"urdb_label":"594976725457a37b1175d089"\n\t\t\t}, \n\t\t\t"LoadProfile":{\n\t\t\t\t"doe_reference_name":"Hospital",\n\t\t\t\t"annual_kwh":1000000\n\t\t\t}\n\t\t}\n\t}\n}\n')])])]),a("h2",{attrs:{id:"setting-custom-assumptions"}},[a("a",{staticClass:"header-anchor",attrs:{href:"#setting-custom-assumptions"}},[e._v("#")]),e._v(" Setting Custom Assumptions")]),e._v(" "),a("p",[e._v("If you wish to use custom input parameters, other than default values, you have a couple of options.")]),e._v(" "),a("ul",[a("li",[a("ol",[a("li",[e._v("Custom hashes, formatted as described above, can be directly paramaterized when invoking "),a("em",[e._v("reopt_json_from_scenario_report")]),e._v(" or "),a("em",[e._v("reopt_jsons_from_scenario_feature_reports")]),e._v(" from a "),a("strong",[e._v("URBANopt::REopt::ScenarioReportAdapter")]),e._v(", or  "),a("em",[e._v("reopt_json_from_feature_report")]),e._v(" from a "),a("strong",[e._v("URBANopt::REopt::FeatureReportAdapter")]),e._v(".")])])]),e._v(" "),a("li",[a("ol",{attrs:{start:"2"}},[a("li",[e._v("Paths to custom hashes, formatted as described above and saved as JSON files in a common folder, can be specified in the input REopt Scenario CSV. See the "),a("a",{attrs:{href:"https://github.com/TK-23/urbanopt-example-geojson-reopt-project.git",target:"_blank",rel:"noopener noreferrer"}},[e._v("example project"),a("OutboundLink")],1),e._v(" for more information on how to do this.")])])])])],1)}),[],!1,null,null,null);t.default=r.exports}}]);