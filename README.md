# Lopata - functional acceptance testing

Motivation: use RSpec for functional testing.

## Installation

    gem install lopata

## Usage

Create new lopata project:

    lopata new <project-name>

Setup environment: edit <project-name>/config/environments/qa.yml for setup project for testing.

Write tests: puts RSpec tests in <project-name>/spec folder.

Run tests:

    cd <project-name>
    lopata
