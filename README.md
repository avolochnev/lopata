# Lopata - functional acceptance testing

Motivation: use RSpec for functional testing.

## Installation

    gem install lopata

## Usage

Create new lopata project:

    lopata new <project-name>

Setup environment: edit <project-name>/config/environments/qa.yml for setup project for testing.

Write tests: puts tests in <project-name>/scenarios folder. Define shared steps in <project-name>/shared_steps folder.

Run tests:

    cd <project-name>
    lopata
