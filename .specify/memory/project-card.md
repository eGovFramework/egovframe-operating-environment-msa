# egovframe-operating-environment-msa: project context

## Role and maintenance boundary

Istio and OpenTelemetry deployment guidance, Docker/Kubernetes manifests, service-management scripts, and the EgovHello example. Preserve service routes, telemetry wiring, deployment resource names, documented import/setup order, and infrastructure boundaries.
This card reflects source inspection at adoption; it does not certify runtime behavior.

## Public entry points and evidence

- `README.md`: import, service build/start/status scripts, Istio/OpenTelemetry documentation, and Docker/Kubernetes guide entry points.
- `import_msa_project.sh`: imports named services from `egovframe-common-components-msa-krds` tag `v4.3.2`; imported services are not part of the initial checkout.
- `pom.xml`: lists imported modules such as ConfigServer and EgovBoard; a clean checkout does not contain those module directories.
- `build.sh`: builds selected imported services using `mvn clean package` and checks ConfigServer/search configuration.
- `EgovHello/pom.xml`: standalone Java 17, Spring Boot 3.2.0, OpenTelemetry 1.31.0 example.
- `docker-deploy/README.md` and `k8s-deploy/README.md`: deployment prerequisites, environment configuration, storage and cluster steps.

## Build and verification entry points

README documents `./import_msa_project.sh` before `./build.sh` and permits service-specific
`./build.sh EgovMobileId`. Import copies external source and is not an adoption check; do not
run it to validate these files. A root Maven build cannot be assumed to work before imports.
The isolated example has the manifest-derived packaging entry point
`mvn -f EgovHello/pom.xml package`; it is not included in root modules or build.sh service
selection. Docker and Kubernetes verification must follow their guide with the real configured
environment, then inspect service health and telemetry rather than equating YAML presence
with successful deployment.

## Environment and evidence limits

Requires external imported services, config repository, database/search systems, container
runtime, and for Kubernetes a compatible cluster/storage/mesh setup. Do not run setup,
cleanup, deployment, or import scripts during adoption. Keep actual passwords, wallets,
certificates and machine paths outside workflow documents. EgovHello dependency review
(fork issue #2) is a separate concern, not an adoption change.
No application build, test suite, formatter, device test, or external service was run for this
workflow-only adoption. A Spec Kit CLI/status and isolated scaffold smoke validate the tooling
only. No CodeGraph index was present in the adoption workspace; targeted file listing and
exact text inspection supplied the evidence, without installing an indexer.

## Upstream and submission baseline

Upstream: [eGovFramework/egovframe-operating-environment-msa](https://github.com/eGovFramework/egovframe-operating-environment-msa). Fetch the actual upstream default branch
and record its exact SHA before preparing `upstream-submit`; do not infer the baseline from
fork work. Preserve an existing submission branch or open PR. Adoption changes are pushed
only to fork `work`; an absent `upstream-submit` is created from the fetched upstream SHA
without adoption commits, as a separate submission baseline.
The [constitution](constitution.md) is the policy source for domain cards, verification, and
work-only artifact isolation. Native OMP commands are in `.omp/commands/`; the bundled bug
workflow provides assess, fix, and test stages. No application fix or PR is part of
this adoption.
