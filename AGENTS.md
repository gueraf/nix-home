# Agents

- Always use `uv run` to execute agents and scripts (do not use ad-hoc python -m or other entrypoints).
- Always use Abseil (absl) libraries for flags and testing. For example:
  - Use absl.flags instead of argparse for flag definitions and parsing.
  - Use absl.testing (absltest) for unit tests.

Examples:

- absl.flags:

  from absl import flags
  FLAGS = flags.FLAGS
  flags.DEFINE_string('name', 'world', 'Name to greet')

- absltest:

  from absl.testing import absltest

  class MyTest(absltest.TestCase):
      def test_example(self):
          self.assertEqual(1 + 1, 2)