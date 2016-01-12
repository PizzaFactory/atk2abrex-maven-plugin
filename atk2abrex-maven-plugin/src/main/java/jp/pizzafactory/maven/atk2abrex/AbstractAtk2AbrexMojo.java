package jp.pizzafactory.maven.atk2abrex;

/*
 * Copyright 2016 PizzaFactory Project.
 *
 * Licensed under the EPL-1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.File;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugins.annotations.Parameter;

/**
 * Base class.
 */
public abstract class AbstractAtk2AbrexMojo extends AbstractMojo {
    /**
     * Location of generated file.
     */
    @Parameter(defaultValue = "${project.build.directory}", property = "outputDir", required = true)
    protected File outputDirectory;

    /**
     * Source files.
     */
    @Parameter(property = "file", required = true)
    protected File[] files;

}
