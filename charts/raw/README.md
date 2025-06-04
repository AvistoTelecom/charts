# raw

This chart takes a list of Kubernetes resources and merges each resource with a default `metadata.labels` map and installs the result.

The Kubernetes resources can be "raw" ones defined under the `resources` key, or "templated" ones defined under the `templates` key.

Some use cases for this chart include Helm-based installation and
maintenance of resources of kinds:
- LimitRange
- PriorityClass
- Secret

## Parameters

### Global

| Name        | Description                              | Value |
| ----------- | ---------------------------------------- | ----- |
| `resources` | List of "raw" Kubernetes resources       | `[]`  |
| `templates` | List of "templated" Kubernetes resources | `[]`  |

## Usage

### Raw resources

#### STEP 1: Create a yaml file containing your raw resources

```yaml
# raw-priority-classes.yaml
resources:
  - apiVersion: scheduling.k8s.io/v1beta1
    kind: PriorityClass
    metadata:
      name: common-critical
    value: 100000000
    globalDefault: false
    description: "This priority class should only be used for critical priority common pods."
```

#### STEP 2: Install your raw resources

```
helm install raw-priority-classes avisto/raw -f raw-priority-classes.yaml
```

### Templated resources

#### STEP 1: Create a yaml file containing your templated resources

```yaml
# values.yaml
mysecret: supersecretvalue

templates:
- |
  apiVersion: v1
  kind: Secret
  metadata:
    name: common-secret
  stringData:
    mykey: {{ .Values.mysecret }}
```

#### STEP 2: Install your templated resources

```
helm install my-secret avisto/raw -f values.yaml
```

## Advanced


`templates` value supports complex construction, as regular Helm templates:

```yaml
persistentVolumeClaims:
  - name: foo
    accessModes: ReadWriteOnce
    size: 10Gi
  - name: bar
    accessModes: ReadWriteMany
    size: 5Gi

templates:
  - |
    {{- range .Values.persistentVolumeClaims }}
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: "pvc-{{ .name }}"
    spec:
      accessModes: {{ .accessModes }}
      resources:
        requests:
          storage: {{ .size }}
    {{- end }}
```

## Fork

This chart has been forked from `itscontained/raw`.
