from http.server import HTTPServer, BaseHTTPRequestHandler
import json, subprocess, logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
IGNORED_NS = ['kube-system','falco','monitoring','ingress-nginx','argocd','local-path-storage']
IGNORED_PODS = ['prometheus','grafana','loki','argocd','falco','nginx-test','coredns']
class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers['Content-Length']))
        try:
            alert = json.loads(body)
            priority = alert.get('priority','')
            fields = alert.get('output_fields',{})
            pod = fields.get('k8s.pod.name','')
            ns = fields.get('k8s.ns.name','default')
            rule = alert.get('rule','')
            logger.info(f"Alert: {priority} - {rule} - Pod: {pod} - NS: {ns}")
            if priority in ['Critical','Warning'] and pod and pod not in ['<NA>','None',None]:
                if ns in IGNORED_NS:
                    logger.info(f"Ignoring system ns: {ns}")
                elif any(pod.startswith(p) for p in IGNORED_PODS):
                    logger.info(f"Ignoring system pod: {pod}")
                else:
                    logger.warning(f"ISOLATING pod: {pod} in {ns}")
                    self.isolate(pod, ns)
        except Exception as e:
            logger.error(f"Error: {e}")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')
    def isolate(self, pod, ns):
        subprocess.run(['/kubectl-bin/kubectl','label','pod',pod,'-n',ns,'isolated=true','--overwrite'])
        policy = f"apiVersion: networking.k8s.io/v1\nkind: NetworkPolicy\nmetadata:\n  name: isolate-{pod}\n  namespace: {ns}\nspec:\n  podSelector:\n    matchLabels:\n      isolated: 'true'\n  policyTypes:\n  - Ingress\n  - Egress"
        r = subprocess.run(['/kubectl-bin/kubectl','apply','-f','-'], input=policy.encode(), capture_output=True)
        logger.info(f"Isolated: {r.returncode == 0}")
    def log_message(self, f, *a): pass
if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 9000), Handler)
    logger.info("Falco Response Handler started on port 9000")
    server.serve_forever()
