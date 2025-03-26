// srcs/requirements/Jenkins/init_scripts/prometheus-config.groovy
import jenkins.model.Jenkins
import io.jenkins.plugins.prometheus.config.PrometheusConfiguration

def instance = Jenkins.getInstance()
def prometheusConfiguration = PrometheusConfiguration.get()

// Configure Prometheus endpoint path
prometheusConfiguration.setPath("prometheus")
prometheusConfiguration.setDefaultNamespace("default")
prometheusConfiguration.setCollectingMetricsPeriodInSeconds(5)
prometheusConfiguration.setProcessingDisabledBuilds(false)
prometheusConfiguration.setPercentiles([50.0d, 95.0d, 99.0d])
prometheusConfiguration.setUseAuthenticatedEndpoint(true)
prometheusConfiguration.setGarbageCollectionMetrics(true)

// Save the configuration
prometheusConfiguration.save()
println("Prometheus plugin configuration completed successfully")