apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nsmgr
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    matchLabels:
      app: nsmgr-daemonset
  template:
    metadata:
      labels:
        app: nsmgr-daemonset
    spec:
      serviceAccount: nsmgr-acc
      containers:
        - name: nsmdp
          image: {{ .Values.registry }}/{{ .Values.org }}/nsmdp:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          env:
            - name: INSECURE
{{- if .Values.insecure }}
              value: "true"
{{- else }}
              value: "false"
{{- end }}
{{- if .Values.global.JaegerTracing }}
            - name: TRACER_ENABLED
              value: "true"
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
          volumeMounts:
            - name: kubelet-socket
              mountPath: /var/lib/kubelet/device-plugins
            - name: nsm-socket
              mountPath: /var/lib/networkservicemesh
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: true
        - name: nsmd
          image: {{ .Values.registry }}/{{ .Values.org }}/nsmd:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          env:
            - name: INSECURE
{{- if .Values.insecure }}
              value: "true"
{{- else }}
              value: "false"
{{- end }}
{{- if .Values.global.JaegerTracing }}
            - name: TRACER_ENABLED
              value: "true"
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
          volumeMounts:
            - name: nsm-socket
              mountPath: /var/lib/networkservicemesh
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: true
            - name: nsm-config-volume
              mountPath: /var/lib/networkservicemesh/config
          livenessProbe:
            httpGet:
              host: "127.0.0.1"
              path: /liveness
              port: 5555
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 3
          readinessProbe:
            httpGet:
              host: "127.0.0.1"
              path: /readiness
              port: 5555
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 3
        - name: nsmd-k8s
          image: {{ .Values.registry }}/{{ .Values.org }}/nsmd-k8s:{{ .Values.tag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          volumeMounts:
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: true
          env:
            - name: INSECURE
{{- if .Values.insecure }}
              value: "true"
{{- else }}
              value: "false"
{{- end }}
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_UID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.uid
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
{{- if .Values.global.JaegerTracing }}
            - name: TRACER_ENABLED
              value: "true"
            - name: JAEGER_AGENT_HOST
              value: jaeger.nsm-system
            - name: JAEGER_AGENT_PORT
              value: "6831"
{{- end }}
      volumes:
        - hostPath:
            path: /var/lib/kubelet/device-plugins
            type: DirectoryOrCreate
          name: kubelet-socket
        - hostPath:
            path: /var/lib/networkservicemesh
            type: DirectoryOrCreate
          name: nsm-socket
        - name: nsm-config-volume
          configMap:
            name: nsm-config
        - hostPath:
            path: /run/spire/sockets
            type: DirectoryOrCreate
          name: spire-agent-socket
