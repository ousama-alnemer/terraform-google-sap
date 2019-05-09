/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "random_id" "random_suffix" {
  byte_length = 4
}

locals {
  gcs_bucket_name = "deployment-bucket-${random_id.random_suffix.hex}"

  # TODO: Add requirements of downloading sotware in README.md of module.
  #gcs_bucket_static_name = "deployment-bucket-static/hana20sps03"
  gcs_bucket_static_name = "hana-gcp-20/hana20sps03"
}

#TODO: Add creation of a network that's similar to app2 
resource "google_storage_bucket" "deployment_bucket" {
  name          = "${local.gcs_bucket_name}"
  force_destroy = true
  location      = "${var.region}"
  storage_class = "REGIONAL"
  project       = "${var.project_id}"
}


module "startup_scripts" {
  source  = "terraform-google-modules/startup-scripts/google"
  version = "0.1.0"
}

data "template_file" "post_deployment_script" {
  template = "${file("${path.cwd}/files/templates/post_deployment_script.tpl")}"

  vars = {

    #sap_hana_id (SID) needs to be lower case logging in with the [SID]adm
    sap_hana_sid = "${lower(module.example.sap_hana_sid)}"
  }
}

data "template_file" "startup_sap_hana" {
  template = "${file("${path.module}/files/startup_sap_hana.tpl")}"
}

resource "google_storage_bucket_object" "post_deployment_script" {
  name    = "post_deployment_script"
  content = "${data.template_file.post_deployment_script.rendered}"
  bucket  = "${google_storage_bucket.deployment_bucket.name}"
}

module "example" {
  source                     = "../../../examples/simple_example"
  project_id                 = "${var.project_id}"
  service_account            = "${var.service_account}"
  instance_type              = "${var.instance_type}"
  sap_hana_deployment_bucket = "${local.gcs_bucket_static_name}"
  subnetwork                 = "default"
  network_tags               = ["foo"]
  startup_script             = "${module.startup_scripts.content}"
  post_deployment_script     = "gs://deployment-bucket-static/post_deployment_test.sh"
  startup_script_custom      = "${data.template_file.startup_sap_hana.rendered}"
}
