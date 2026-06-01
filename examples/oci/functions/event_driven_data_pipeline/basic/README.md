# OCI Event-Driven Data Pipeline Basic Example

This example is a thin wrapper around the shared **event_driven_data_pipeline** pattern.

It demonstrates:

- a public API Gateway entry point
- a private OCI Functions application with three functions
- asynchronous handoff through OCI Streaming
- Service Connector Hub delivery into a collector function
- persistence into Autonomous Database

## Architecture Overview

![OCI event-driven data pipeline architecture](images/event_driven_data_pipeline_basic_architecture.png)

Figure 1. `event_driven_data_pipeline` runtime flow: `fnadbsetup` bootstraps ADB, `fninitiator` accepts the API request and writes to Streaming, Service Connector Hub invokes `fncollector`, and the collector persists the final record in Autonomous Database.

## OCI Console Verification

![OCI event-driven data pipeline API Gateway](images/event_driven_data_pipeline_basic_oci_console1.png)

Figure 2. Public API Gateway `fk-event-driven-data-pipeline-gateway` is active and exposes the `fninitiator` route used for the smoke test.

![OCI event-driven data pipeline Functions application](images/event_driven_data_pipeline_basic_oci_console2.png)

Figure 3. Functions application `fk-event-driven-data-pipeline-dev-app` contains the three runtime components: `fninitiator`, `fncollector`, and `fnadbsetup`.

![OCI event-driven data pipeline stream](images/event_driven_data_pipeline_basic_oci_console3.png)

Figure 4. OCI Streaming provides the asynchronous handoff buffer used by the initiator function.

![OCI event-driven data pipeline Service Connector Hub](images/event_driven_data_pipeline_basic_oci_console4.png)

Figure 5. Service Connector Hub is active and connects the stream source to the collector function target.

![OCI event-driven data pipeline Service Connector configuration](images/event_driven_data_pipeline_basic_oci_console5.png)

Figure 6. The connector configuration shows the exact source stream and target function wiring for the runtime path.

![OCI event-driven data pipeline Autonomous Database](images/event_driven_data_pipeline_basic_oci_console6.png)

Figure 7. Autonomous Database `FoggyKitchenADB` is available and acts as the persistence layer for processed records.

![OCI event-driven data pipeline ADB data verification](images/event_driven_data_pipeline_basic_oci_console7.png)

Figure 8. Database Actions confirms that the test payload reached `APPUSER.IOT_DATA`, including inserted `device777` rows.

## Files

- `landing-zone.yaml`: payload describing the event-driven data pipeline pattern
- `main.tf`: thin wrapper around the shared pattern
- `providers.tf`: OCI provider configuration
- `variables.tf`: provider and secret inputs
- `outputs.tf`: useful outputs
- `terraform.tfvars.example`: example provider values
- `functions/`: initiator, collector, and ADB bootstrap function sources

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu plan
```

## Notes

- this example is intentionally based on the complete architecture explored in `lesson7`
- the API route publishes only the initiator function; downstream processing is asynchronous
- ADB passwords are required because the pattern includes both bootstrap and application-side database access

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
