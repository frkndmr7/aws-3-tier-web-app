output "final_vpc_id" {
  value = module.network.vpc_id
}

output "website_url" {
  value = "http://${module.compute.alb_dns_name}"
}