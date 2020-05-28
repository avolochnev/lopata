# Lopata

Functional acceptance testing using Ruby.

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

## Documentation

See [features description](https://github.com/avolochnev/lopata/tree/master/features) for documentation.