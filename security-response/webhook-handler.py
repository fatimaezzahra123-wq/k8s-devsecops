from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FalcoWebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)
        
        try:
            alert = json.loads(body)
            priority = alert.get('priority', '')
            pod_name = alert.get('output_fields', {}).get('k8s.pod.name', '')
            namespace = alert.get('output_fields', {}).get('k8s.ns.name', 'default')
            rule = alert.get('rule', '')

            logger.info(f"Alert received: {priority} - {rule} - Pod: {pod_name}")

            if priority == 'Critical' and pod_name and pod_name != '<NA>':
                logger.warning(f"🚨 CRITICAL alert! Isolating pod: {pod_name}")
                self.isolate_pod(pod_name, namespace)

        except Exception as e:
            logger.error(f"Error processing alert: {e}")

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')

    def isolate_pod(self, pod_name, namespace):
        policy = f"""
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-{pod_name}
  namespace: {namespace}
spec:
  podSelector:
    matchLabels:
      isolated: "true"
  policyTypes:
  - Ingress
  - Egress
"""
        # Label the pod first
        subprocess.run([
            'kubectl', 'label', 'pod', pod_name,
            '-n', namespace,
            'isolated=true',
            '--overwrite'
        ])

        # Apply NetworkPolicy
        result = subprocess.run(
            ['kubectl', 'apply', '-f', '-'],
            input=policy.encode(),
            capture_output=True
        )
        
        if result.returncode == 0:
            logger.info(f"✅ Pod {pod_name} isolated successfully!")
        else:
            logger.error(f"❌ Failed to isolate pod: {result.stderr.decode()}")

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 9000), FalcoWebhookHandler)
    logger.info("🚀 Falco Webhook Handler started on port 9000")
    server.serve_forever()
