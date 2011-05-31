# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tn_pdf/version"

Gem::Specification.new do |s|
  s.name        = "tn_pdf"
  s.version     = TnPDF::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Renato Riccieri Santos Zannon"]
  s.email       = ["zannon@tecnologiaenegocios.com.br"]
  s.summary = %q{A simple wrapper around prawn, devised to the generation of table-centric reports}

  s.rubyforge_project = "tn_pdf"

  s.add_dependency('prawn', '~> 0.11.1')
  s.add_dependency('activesupport')

  s.add_development_dependency('rspec', '~> 2.6.0')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
end
