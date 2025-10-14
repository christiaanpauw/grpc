# ACM0001: Flaring or use of landfill gas

## Overview
ACM0001 is a consolidated Clean Development Mechanism (CDM) methodology for project activities that capture landfill gas (LFG) from solid waste disposal sites and either flare the gas or use it for energy. The methodology quantifies the emission reductions that occur when methane emissions from the landfill are avoided or destroyed, taking into account project emissions and potential leakage.

## Applicability conditions
- The project installs or expands a system that collects landfill gas from a managed solid waste disposal site and either combusts it in a flare or utilizes it for electricity, thermal energy, or other approved uses.
- The landfill is not already subject to mandatory LFG capture and destruction requirements that would result in equivalent methane control in the absence of the project. If legal requirements exist, the baseline must reflect the level of control that would actually be achieved without the CDM intervention.
- The captured gas is not vented to the atmosphere except for safety or maintenance events, and any emergency venting is monitored and reported.
- The project does not divert waste that would otherwise be disposed in another site where methane emissions are already being captured and destroyed.
- The activity complies with national and local regulations governing waste management, gas flaring, power generation, and worker safety.

## Project boundary
The project boundary includes the physical landfill, the gas collection network (wells, piping, condensate management), gas treatment and compression systems, flares, combustion or utilization equipment (engines, boilers, direct thermal users), and any electricity or heat export interfaces. Greenhouse gases considered are:
- **CH₄**: emissions avoided from the landfill surface (baseline) and residual methane slip from flares or engines (project emissions).
- **CO₂**: emissions from auxiliary fossil fuel or electricity consumption within the project boundary and, where relevant, displacement of fossil-based grid electricity or heat in the baseline.
- **N₂O**: normally insignificant but to be considered if the destruction or utilization technology results in measurable nitrous oxide emissions.

## Baseline scenario
In the absence of the project, landfill gas is typically emitted to the atmosphere or occasionally flared at low efficiency. The baseline methane emissions (\(BE_{CH_4,y}\)) are calculated from the quantity of methane that would have been released without the project, subtracting any fraction that would have been destroyed in the baseline due to existing control measures or regulatory compliance. Methane quantities are determined using either the first-order decay model for solid waste disposal sites (per the CDM "Tool to determine methane emissions avoided from disposal of waste at a solid waste disposal site") or direct measurements where credible historic data are available.

## Additionality demonstration
Project proponents use either the CDM "Tool for the demonstration and assessment of additionality" or the combined baseline and additionality tool to show that the investment faces barriers or is not the most economically attractive option without carbon revenue. Common barriers include the absence of mandatory gas capture requirements, insufficient financial returns from energy sales alone, and technology risks related to gas collection efficiency. Where positive lists issued by the Executive Board apply (e.g., for greenfield capture at unmanaged sites), the project may demonstrate automatic additionality, but supporting evidence must be retained.

## Emission reduction calculation
Emission reductions for year \(y\) are determined as:
\[
ER_y = BE_{CH_4,y} - PE_y - LE_y
\]
where:
- \(BE_{CH_4,y}\): Baseline methane emissions avoided (tCO₂e).
- \(PE_y\): Project emissions, including methane that escapes destruction (e.g., due to flare downtime), CO₂ emissions from auxiliary fossil fuel or grid electricity use, and any fugitive methane from gas handling equipment.
- \(LE_y\): Leakage emissions, such as emissions associated with fossil fuels used to transport residues or impacts on other waste disposal sites if waste diversion occurs.

For projects that generate electricity or thermal energy, the methodology allows crediting of displacement of fossil-derived energy using the appropriate grid emission factor or thermal baseline, provided double counting is avoided.

## Monitoring requirements
- Continuous metering of landfill gas volumetric flow and temperature/pressure to determine the actual volume collected.
- Regular sampling (at least monthly) of methane concentration in the collected gas.
- Logging of flare operating hours, combustion temperature, and automatic shutdown events to confirm destruction efficiency.
- Metering of electricity or thermal energy generated and exported, along with auxiliary energy consumption.
- Tracking of any emergency venting, system downtime, or maintenance activities that could result in methane emissions.
- Calibration and maintenance records for all critical measurement equipment, consistent with manufacturer recommendations and CDM monitoring guidelines.

## Data and parameters
| Parameter | Unit | Source / Monitoring | Notes |
|-----------|------|--------------------|-------|
| \(Q_{LFG,y}\) | m³ | Measured continuously | Total volume of landfill gas collected in year \(y\). |
| \(w_{CH_4,y}\) | Fraction | Laboratory analysis | Weighted average methane content of collected LFG. |
| \(F_{flare,y}\) | Fraction | Operational records | Fraction of time the flare (or destruction device) operates within specification. |
| \(EF_{grid}\) | tCO₂/MWh | Official grid emission factor | Used when electricity generation displaces grid power. |
| \(EC_{aux,y}\) | MWh or GJ | Metered | Auxiliary electricity or fossil fuel consumption attributable to the project. |
| \(GWP_{CH_4}\) | tCO₂e/tCH₄ | IPCC assessment report adopted by the CMP | Global warming potential of methane applicable to the crediting period. |

## Implementation checklist
1. **Site assessment** – Characterize the landfill, waste composition, historical disposal rates, and any existing gas control measures. Establish data needed for the methane generation model if direct measurements are unavailable.
2. **Design the capture and destruction system** – Specify collection wells, piping, condensate management, compression, flaring, and/or energy utilization equipment. Document expected gas flow, destruction efficiency, and redundancy provisions.
3. **Baseline and additionality analysis** – Apply the selected CDM tools, determine the plausible baseline scenario, and document financial or regulatory barriers. Quantify baseline emissions using model inputs consistent with the methodology.
4. **Monitoring plan development** – Identify meters, sampling frequencies, calibration procedures, data logging systems, and roles/responsibilities. Include contingency procedures for equipment failures and data gaps.
5. **Emission reduction calculation** – Implement data processing routines to convert measured flows and methane fractions into CH₄ quantities, apply destruction efficiencies, calculate project emissions (e.g., auxiliary energy, methane slip), and determine leakage.
6. **Quality assurance and reporting** – Maintain calibration certificates, operator training records, and evidence of compliance with environmental and safety regulations. Prepare annual monitoring reports summarizing data, calculations, and any corrective actions.
